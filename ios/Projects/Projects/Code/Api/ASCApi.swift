//
//  ASCApi.swift
//  Projects
//
//  Created by Alexander Yuzhin on 3/3/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import Foundation
import Alamofire

typealias ASCApiCompletionHandler = (_ result: Any?, _ error: Error?, _ response: Any?) -> Void
typealias ASCApiProgressHandler = (_ progress: Double, _ result: Any?, _ error: Error?, _ response: Any?) -> Void

enum ASCCategoryType: Int {
    case unknown            = 0
    case projects           = 1
    case milestones         = 2
    case tasks              = 3
    case discussions        = 5
    case timeTracking       = 6
    case documents          = 8
}

enum ASCFolderType: Int {
    case unknown            = 0
    case cloudCommon        = 1
    case cloudBunch         = 2
    case cloudTrash         = 3
    case cloudUser          = 5
    case cloudShare         = 6
    case cloudProjects      = 8
    case deviceDocuments    = 9
}

enum ASCFilterType: Int {
    case none               = 0
    case filesOnly          = 1
    case foldersOnly        = 2
    case documentsOnly      = 3
    case presentationsOnly  = 4
    case spreadsheetsOnly   = 5
    case imagesOnly         = 7
    case byUser             = 8
    case byDepartment       = 9
}

enum ASCFileStatus: Int {
    case none               = 0x0
    case isEditing          = 0x1
    case isNew              = 0x2
    case isConverting       = 0x4
    case isOriginal         = 0x8
    case backup             = 0x10
}

enum ASCEntityAccess: Int {
    case none               = 0
    case readWrite          = 1
    case read               = 2
    case restrict           = 3
}

enum ASCShareType: Int {
    case none               = 0
    case full               = 1
    case read               = 2
    case deny               = 3
    case varies             = 4
}

extension ASCApi {
    // Api version
    static private let version = "2.0"
    
    // Api paths
    static public let apiAuthentication         = "api/\(version)/authentication"
    static public let apiAuthenticationPhone    = "api/\(version)/authentication/setphone"
    static public let apiAuthenticationCode     = "api/\(version)/authentication/sendsms"
    static public let apiCapabilities           = "api/\(version)/capabilities"
    static public let apiDeviceRegistration     = "api/\(version)/portal/mobile/registration"
    static public let apiPeopleSelf             = "api/\(version)/people/@self"
    static public let apiFilesPath              = "api/\(version)/files/"
    static public let apiFolderProjects         = "@projects"
    static public let apiUsers                  = "api/\(version)/people"
    static public let apiGroups                 = "api/\(version)/group"
    static public let apiProjects               = "api/\(version)/project"
}

extension ASCApi {
    static public let errorPaymentRequired = "PaymentRequired"
}

class ASCAccessTokenAdapter: RequestAdapter {
    private let accessToken: String
    
    init(accessToken: String) {
        self.accessToken = accessToken
    }
    
    func adapt(_ urlRequest: URLRequest) throws -> URLRequest {
        var urlRequest = urlRequest
        urlRequest.setValue(accessToken, forHTTPHeaderField: "Authorization")
        
        return urlRequest
    }
}

class ASCServerTrustPolicyManager: ServerTrustPolicyManager {
    override func serverTrustPolicy(forHost host: String) -> ServerTrustPolicy? {
        return .disableEvaluation
    }
}

class ASCApi {
    public static let shared = ASCApi()
    
    public var baseUrl: String? = nil {
        didSet {
            //
        }
    }
    public var token: String? = nil {
        didSet {
            manager.adapter = ASCAccessTokenAdapter(accessToken: token ?? "")
        }
    }
    public var isReachable: Bool {
        get {
            return NetworkReachabilityManager()!.isReachable
        }
    }
    
    private var manager: Alamofire.SessionManager
    private var reachabilityManager: NetworkReachabilityManager?
    
    required init () {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30 // seconds
        configuration.timeoutIntervalForResource = 30
        configuration.httpAdditionalHeaders = SessionManager.defaultHTTPHeaders
        
        manager = SessionManager(
            configuration: configuration,
            serverTrustPolicyManager: ASCServerTrustPolicyManager(policies: [:])
        )
        
        // Reachability        
        reachabilityManager = NetworkReachabilityManager()
        if let reachability = reachabilityManager {
            reachability.listener = { status in
                debugPrint("Network Status Changed: \(status)")
                DispatchQueue.main.async(execute: {
                    NotificationCenter.default.post(name: ASCConstants.Notifications.networkStatusChanged, object: nil, userInfo: ["status": status])
                })
            }
            reachability.startListening()
        }
    }
    
    static public func get(_ path: String, parameters: Parameters? = nil, encoding: ParameterEncoding = URLEncoding.methodDependent, completion: @escaping ASCApiCompletionHandler) {
        guard let baseUrl = ASCApi.shared.baseUrl else {
            print("Error: ASCApi no baseUrl")
            completion(nil, nil, nil)
            return
        }
        
        guard let encodePath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            print("Error: Encoding path")
            completion(nil, nil, nil)
            return
        }
        
        let url = "\(baseUrl)/\(encodePath).json"
        
        ASCApi.shared.manager
            .request(url, method: .get, parameters: parameters, encoding: encoding, headers: nil)
            .validate()
            .validate(contentType: ["application/json"])
            .responseJSON { response in
                DispatchQueue.main.async(execute: {
                    switch response.result {
                    case .success(let responseJson):
                        if let responseJson = responseJson as? [String: Any] {
                            if let result = responseJson["response"] {
                                completion(result, nil, response)
                                return
                            }
                        }
                        
                        completion(nil, nil, response)
                    case .failure(let error):
                        completion(nil, error, response)
                        debugPrint(response)
                    }
                })
        }
    }
    
    static public func post(_ path: String, parameters: Parameters? = nil, encoding: ParameterEncoding = URLEncoding.default, completion: @escaping ASCApiCompletionHandler) {
        guard let baseUrl = ASCApi.shared.baseUrl else {
            print("Error: ASCApi no baseUrl")
            completion(nil, nil, nil)
            return
        }
        
        guard let encodePath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            print("Error: Encoding path")
            completion(nil, nil, nil)
            return
        }
        
        let url = "\(baseUrl)/\(encodePath).json"
        
        ASCApi.shared.manager
            .request(url, method: .post, parameters: parameters, encoding: encoding, headers: nil)
            .validate()
            .validate(contentType: ["application/json"])
            .responseJSON { response in
                DispatchQueue.main.async(execute: {
                    switch response.result {
                    case .success(let responseJson):
                        if let responseJson = responseJson as? [String: Any] {
                            if let result = responseJson["response"] {
                                completion(result, nil, response)
                                return
                            }
                        }
                        
                        completion(nil, nil, response)
                    case .failure(let error):
                        completion(nil, error, response)
                        debugPrint(response)
                    }
                })
        }
    }
    
    static public func put(_ path: String, parameters: Parameters? = nil, encoding: ParameterEncoding = URLEncoding.default, completion: @escaping ASCApiCompletionHandler) {
        guard let baseUrl = ASCApi.shared.baseUrl else {
            print("Error: ASCApi no baseUrl")
            completion(nil, nil, nil)
            return
        }
        
        guard let encodePath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            print("Error: Encoding path")
            completion(nil, nil, nil)
            return
        }
        
        let url = "\(baseUrl)/\(encodePath).json"
        
        ASCApi.shared.manager
            .request(url, method: .put, parameters: parameters, encoding: encoding, headers: nil)
            .validate()
            .validate(contentType: ["application/json"])
            .responseJSON { response in
                DispatchQueue.main.async(execute: {
                    switch response.result {
                    case .success(let responseJson):
                        if let responseJson = responseJson as? [String: Any] {
                            if let result = responseJson["response"] {
                                completion(result, nil, response)
                                return
                            }
                        }
                        
                        completion(nil, nil, response)
                    case .failure(let error):
                        completion(nil, error, response)
                        debugPrint(response)
                    }
                })
        }
    }
    
    static public func delete(_ path: String, parameters: Parameters? = nil, encoding: ParameterEncoding = URLEncoding.default, completion: @escaping ASCApiCompletionHandler) {
        guard let baseUrl = ASCApi.shared.baseUrl else {
            print("Error: ASCApi no baseUrl")
            completion(nil, nil, nil)
            return
        }
        
        guard let encodePath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            print("Error: Encoding path")
            completion(nil, nil, nil)
            return
        }
        
        let url = "\(baseUrl)/\(encodePath).json"
        
        ASCApi.shared.manager
            .request(url, method: .delete, parameters: parameters, encoding: encoding, headers: nil)
            .validate()
            .validate(contentType: ["application/json"])
            .responseJSON { response in
                DispatchQueue.main.async(execute: {
                    switch response.result {
                    case .success(let responseJson):
                        if let responseJson = responseJson as? [String: Any] {
                            if let result = responseJson["response"] {
                                completion(result, nil, response)
                                return
                            }
                        }
                        
                        completion(nil, nil, response)
                    case .failure(let error):
                        completion(nil, error, response)
                        debugPrint(response)
                    }
                })
        }
    }
    
    static public func download(_ path: String, to: URL, processing: @escaping ASCApiProgressHandler) {
        guard let _ = ASCApi.shared.baseUrl else {
            print("Error: ASCApi no baseUrl")
            processing(0, nil, nil, nil)
            return
        }
        
        if let portalUrl = ASCApi.absoluteUrl(from: URL(string: path)) {
            let destination: DownloadRequest.DownloadFileDestination = { url, respons in
                return (to, [.removePreviousFile, .createIntermediateDirectories])
            }
            
            ASCApi.shared.manager.download(portalUrl, to: destination)
                .downloadProgress { progress in
                    DispatchQueue.main.async(execute: {
                        processing(progress.fractionCompleted, nil, nil, nil)
                    })
                }
                .responseData { response in
                    DispatchQueue.main.async(execute: {
                        processing(1.0, response.result.value, response.error, response)
                    })
            }            
        }
    }
    
    static public func upload(_ path: String, data: Data, parameters: Parameters? = nil, method: HTTPMethod = .post, processing: @escaping ASCApiProgressHandler) {
        guard let baseUrl = ASCApi.shared.baseUrl else {
            print("Error: ASCApi no baseUrl")
            processing(0, nil, nil, nil)
            return
        }
        
        guard let encodePath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            print("Error: Encoding path")
            processing(0, nil, nil, nil)
            return
        }
        
        let portalUrl = "\(baseUrl)/\(encodePath).json"
        let fields: HTTPHeaders = [
            "Content-Length": String(data.count)
        ]
        
        let requestPath = Alamofire.request(portalUrl, method: .get, parameters: parameters, encoding: URLEncoding.default, headers: fields);
        
        if let url = requestPath.request?.url {
            var commonProgress: Double = 0
            ASCApi.shared.manager.upload(data, to: url, method: method, headers: fields)
                .uploadProgress { progress in
                    DispatchQueue.main.async(execute: {
                        commonProgress = progress.fractionCompleted
                        processing(progress.fractionCompleted, nil, nil, nil)
                    })
                }
                .responseJSON { response in
                    DispatchQueue.main.async(execute: {
                        switch response.result {
                        case .success(let responseJson):
                            if let responseJson = responseJson as? [String: Any] {
                                if let result = responseJson["response"] {
                                    processing(1.0, result, nil, response)
                                    return
                                }
                            }
                            
                            processing(1.0, nil, response.error, response)
                        case .failure(let error):
                            if commonProgress <= 0.01 {
                                processing(1.0, nil, error, response)
                            }
                            debugPrint(response)
                        }
                    })
            }
        }
    }

    // MARK: - Helpers
    
    static public func errorInfo(by response: Any) -> [String: Any]? {
        if let response = response as? DataResponse<Any> {
            if let data = response.data {
                do {
                    return try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
                } catch {
                    print(error)
                }
            }
        }
        
        return nil
    }
    
    static public func errorMessage(by response: Any) -> String {
        if let errorInfo = self.errorInfo(by: response) {
            if let error = errorInfo["error"] as? [String: Any], let message = error["message"] as? String {
                return message
            }
        }
        
        return String.localizedStringWithFormat("The %@ server is not available.", ASCApi.shared.baseUrl ?? "")
    }
    
    static public func cancelAllTasks() {
        ASCApi.shared.manager.session.getAllTasks { tasks in
            tasks.forEach { $0.cancel() }
        }
    }
    
    static public func absoluteUrl(from url: URL?) -> URL? {
        if let url = url {
            if let _ = url.host {
                return url
            } else {
                return URL(string: (ASCApi.shared.baseUrl ?? "") + url.absoluteString)
            }
        }
        return nil
    }
}
