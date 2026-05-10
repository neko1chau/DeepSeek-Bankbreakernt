import Foundation

struct ReleaseInfo: Codable, Equatable {
    let tagName: String
    let name: String
    let body: String
    let downloadUrl: String
    let version: String

    init(from decoder: Decoder) throws {
        let root = try decoder.container(keyedBy: RootKeys.self)

        tagName = try root.decode(String.self, forKey: .tagName)
        name = try root.decode(String.self, forKey: .name)
        body = try root.decodeIfPresent(String.self, forKey: .body) ?? ""

        var downloadUrl = ""
        let assets = try root.decode([AssetInfo].self, forKey: .assets)
        if let firstAsset = assets.first {
            downloadUrl = firstAsset.browserDownloadUrl
        }
        self.downloadUrl = downloadUrl
        version = name
    }

    enum RootKeys: String, CodingKey {
        case tagName = "tag_name"
        case name, body, assets
    }

    struct AssetInfo: Codable {
        let browserDownloadUrl: String

        enum CodingKeys: String, CodingKey {
            case browserDownloadUrl = "browser_download_url"
        }
    }
}

enum UpdateError: LocalizedError {
    case networkError(String)
    case parseError
    case noAsset
    case downloadFailed
    case rateLimited

    var errorDescription: String? {
        switch self {
        case .networkError(let detail): return "网络请求失败: \(detail)"
        case .parseError: return "解析响应失败"
        case .noAsset: return "未找到下载资源"
        case .downloadFailed: return "下载失败"
        case .rateLimited: return "请求过于频繁，请稍后再试"
        }
    }
}

actor UpdateService {
    static let shared = UpdateService()

    private let repoOwner = "neko1chau"
    private let repoName = "DeepSeek-Bankbreakernt"
    private let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"

    private init() {}

    func checkForUpdate() async throws -> ReleaseInfo? {
        let url = URL(string: "https://api.github.com/repos/\(repoOwner)/\(repoName)/releases/latest")!
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("DeepSeekBankbreaknt/1.0", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 15

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw UpdateError.networkError(error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw UpdateError.networkError("无法连接到服务器")
        }

        switch httpResponse.statusCode {
        case 200:
            break
        case 403, 429:
            throw UpdateError.rateLimited
        case 404:
            throw UpdateError.networkError("未找到发布信息")
        default:
            throw UpdateError.networkError("服务器返回错误 (HTTP \(httpResponse.statusCode))")
        }

        do {
            let decoder = JSONDecoder()
            let release = try decoder.decode(ReleaseInfo.self, from: data)

            if isNewerVersion(release.version, than: currentVersion) {
                return release
            }
            return nil
        } catch {
            throw UpdateError.parseError
        }
    }

    func downloadUpdate(from urlString: String, progressHandler: @escaping (Double) -> Void) async throws -> URL {
        guard URL(string: urlString) != nil else {
            throw UpdateError.networkError("无效的下载链接")
        }

        let (tempUrl, response) = try await URLSession.shared.download(from: URL(string: urlString)!)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw UpdateError.downloadFailed
        }

        let destUrl = FileManager.default.temporaryDirectory.appendingPathComponent("DeepSeekBankbreaknt.dmg")
        try? FileManager.default.removeItem(at: destUrl)
        try FileManager.default.moveItem(at: tempUrl, to: destUrl)

        return destUrl
    }

    private func isNewerVersion(_ newVersion: String, than current: String) -> Bool {
        let newParts = newVersion.split(separator: ".").compactMap { Int($0) }
        let currentParts = current.split(separator: ".").compactMap { Int($0) }

        for i in 0..<max(newParts.count, currentParts.count) {
            let new = i < newParts.count ? newParts[i] : 0
            let old = i < currentParts.count ? currentParts[i] : 0
            if new > old { return true }
            if new < old { return false }
        }
        return false
    }
}