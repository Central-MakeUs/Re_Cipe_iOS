//
//  LoginService.swift
//  Recipe
//
//  Created by KindSoft on 2023/07/18.
//

import Foundation
import RxSwift
import Alamofire

enum AppleLoginError: Error {
    case httpBodyError
    case networkError
    case decodingError(Error)
}

struct LoginService{
    static let shared = LoginService()

    // MARK: - [Post Body Json Request 방식 http 요청 실시]
    
    func appleRegister(idToken: String, nickName: String, completion: @escaping (Result<LoginSucess, Error>) -> Void) {
        print(#function)
        let url = URL(string: "https://api.rec1pe.store/api/v1/auth/apple/signup")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let parameters: [String: Any] = [
            "idToken" : idToken,
            "nickname": nickName
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        } catch {
            print("parameter Error")
            completion(.failure(error))
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("dataTask Error")
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                print("invalidResponse Error")
                completion(.failure(NetworkError.invalidResponse))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let decodedData = try decoder.decode(LoginTokenInfo.self, from: data)
                print(decodedData)
                KeyChain.shared.create(account: .accessToken, data: decodedData.data.accessToken)
                KeyChain.shared.create(account: .refreshToken, data: decodedData.data.refreshToken)
                
                DispatchQueue.main.async {
                    // You might call the completion handler here to signal success
                }
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    func appleRegister(idToken: String, nickName: String) async throws -> LoginTokenInfo {
        let url = URL(string: "https://api.rec1pe.store/api/v1/auth/apple/signup")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let parameters: [String: Any] = [
            "idToken" : idToken,
            "nickname": nickName
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        } catch {
            throw error
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NetworkError.invalidResponse
        }
        
        do {
            let decoder = JSONDecoder()
            let decodedData = try decoder.decode(LoginTokenInfo.self, from: data)
            KeyChain.shared.create(account: .accessToken, data: decodedData.data.accessToken)
            KeyChain.shared.create(account: .refreshToken, data: decodedData.data.refreshToken)
            
            // Assuming self.appleLogin is a synchronous function
    //        self.appleLogin(accessToken: KeyChain.shared.read(account: .idToken))
            
            return decodedData
        } catch {
            throw error
        }
    }
    
    func googleRegister(idToken: String, nickName: String) async throws -> LoginTokenInfo {
        let url = URL(string: "https://api.rec1pe.store/api/v1/auth/google/signup")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(idToken, forHTTPHeaderField: "auth-token")
        
        let parameters: [String: Any] = [
            "nickname": nickName
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        } catch {
            throw error
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        print(String(data: data, encoding: .utf8))
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NetworkError.invalidResponse
        }
        
        do {
            let decoder = JSONDecoder()
            let decodedData = try decoder.decode(LoginTokenInfo.self, from: data)
            KeyChain.shared.create(account: .accessToken, data: decodedData.data.accessToken)
            KeyChain.shared.create(account: .refreshToken, data: decodedData.data.refreshToken)
            
            // Assuming self.appleLogin is a synchronous function
    //        self.appleLogin(accessToken: KeyChain.shared.read(account: .idToken))
            
            return decodedData
        } catch {
            throw error
        }
    }
    
    
    func appleLogin(accessToken: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        let url = URL(string: "https://api.rec1pe.store/api/v1/auth/apple/signin")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let parameters: [String: Any] = [
            "idToken" : accessToken,
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        } catch {
            print("httpBody Error")
            completion(.failure(error))
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("dataTask Error")
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                print("data = data error")
                completion(.failure(NetworkError.invalidResponse))
                return
            }
            print(String(data: data, encoding: .utf8))
            
            do {
                let decoder = JSONDecoder()
                let decodedData = try decoder.decode(MemberCheck.self, from: data)

                    KeyChain.shared.create(account: .accessToken,
                                           data: decodedData.data.jwtTokens.accessToken)
                if let refresh = decodedData.data.jwtTokens.refreshToken {
                    KeyChain.shared.create(account: .refreshToken,
                                           data: refresh)
                }
                
                DispatchQueue.main.async {
                    completion(.success(decodedData.data.isMember))
                }
            } catch {
                print("그냥 error")
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    func googleLogin(accessToken: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        let url = URL(string: "https://api.rec1pe.store/api/v1/auth/google/signin")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.headers = ["auth-token": accessToken]
        
        let parameters: [String: Any] = [
            "auth-token" : accessToken,
        ]
        
        do {
//            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        } catch {
            print("httpBody Error")
            completion(.failure(error))
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("dataTask Error")
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                print("data = data error")
                completion(.failure(NetworkError.invalidResponse))
                return
            }
            print(String(data: data, encoding: .utf8))
            
            do {
                let decoder = JSONDecoder()
                let decodedData = try decoder.decode(MemberCheck.self, from: data)

                    KeyChain.shared.create(account: .accessToken,
                                           data: decodedData.data.jwtTokens.accessToken)
                if let refresh = decodedData.data.jwtTokens.refreshToken {
                    KeyChain.shared.create(account: .refreshToken,
                                           data: refresh)
                }
                
                DispatchQueue.main.async {
                    completion(.success(decodedData.data.isMember))
                }
            } catch {
                print("그냥 error")
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    func appleLoginRx(accessToken: String) -> Observable<LoginSucess> {
        return Observable.create { observer in
            let url = URL(string: "https://api.rec1pe.store/api/v1/auth/apple/signin")!
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let parameters: [String: Any] = [
                "idToken" : accessToken,
            ]
            
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
            } catch {
                observer.onError(AppleLoginError.httpBodyError)
                return Disposables.create()
            }
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    observer.onError(error)
                    return
                }
                
                guard let data = data else {
                    observer.onError(AppleLoginError.networkError)
                    return
                }
                
                do {
                    let decoder = JSONDecoder()
                    let decodedData = try decoder.decode(LoginSucess.self, from: data)
                    KeyChain.shared.create(account: .accessToken,
                                           data: decodedData.data.jwtTokens.accessToken)
                    KeyChain.shared.create(account: .refreshToken,
                                           data: decodedData.data.jwtTokens.refreshToken)
                    
                    observer.onNext(decodedData)
                    observer.onCompleted()
                } catch {
                    observer.onError(AppleLoginError.decodingError(error))
                }
            }
            
            task.resume()
            
            return Disposables.create {
                task.cancel()
            }
        }
    }
    
    func googleLoginRx(accessToken: String) -> Observable<LoginSucess> {
        return Observable.create { observer in
            let url = URL(string: "https://api.rec1pe.store/api/v1/auth/google/signin")!
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue(KeyChain.shared.read(account: .idToken), forHTTPHeaderField: "auth-token")

            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    observer.onError(error)
                    return
                }
                
                guard let data = data else {
                    observer.onError(AppleLoginError.networkError)
                    return
                }
                
                do {
                    let decoder = JSONDecoder()
                    let decodedData = try decoder.decode(LoginSucess.self, from: data)
                    KeyChain.shared.create(account: .accessToken,
                                           data: decodedData.data.jwtTokens.accessToken)
                    KeyChain.shared.create(account: .refreshToken,
                                           data: decodedData.data.jwtTokens.refreshToken)
                    
                    observer.onNext(decodedData)
                    observer.onCompleted()
                } catch {
                    observer.onError(AppleLoginError.decodingError(error))
                }
            }
            
            task.resume()
            
            return Disposables.create {
                task.cancel()
            }
        }
    }
    
    // MARK: - [Post Body Json Request 방식 http 요청 실시]
    func nickNameCheck(nickName: String, completion: @escaping (_ data: Bool) -> Void){
        print(#function)
        // [http 요청 주소 지정]
        let url = "https://api.rec1pe.store/api/v1/users/verify-nickname"
        // [http 요청 헤더 지정]
        let header : HTTPHeaders = [
            "Content-Type" : "application/json"
        ]
        // [http 요청 파라미터 지정 실시]
        let bodyData : Parameters = [
            "nickname" : nickName
        ]
        
        AF.request(
            url, // [주소]
            method: .post, // [전송 타입]
            parameters: bodyData, // [전송 데이터]
            encoding: JSONEncoding.default, // [인코딩 스타일]
            headers: header // [헤더 지정]
        )
        .validate(statusCode: 200..<300)
        .responseData { response in
            switch response.result {
            case .success(let res):
                do {
                    let decoder = JSONDecoder()
                    print(String(data: res, encoding: .utf8))
                    guard let decodedData = try? decoder.decode(Welcome.self, from: res) else {
                        print("catch")
                        return
                    }
                    completion(decodedData.data.isDuplicated)
                    // [비동기 작업 수행]
                    DispatchQueue.main.async {
                    }
                }
                catch (let err){
                    print("catch :: ", err.localizedDescription)
                }
                break
            case .failure(let err):
                print("응답 코드 :: ", response.response?.statusCode ?? 0)
                print("에 러 :: ", err.localizedDescription)
                break
            }
        }
    }
    
    func nickNameChange(nickName: String, completion: @escaping (_ data: ReviewResult) -> Void){
        print(#function)
        // [http 요청 주소 지정]
        let url = "https://api.rec1pe.store:443/api/v1/users/change-nickname"
        // [http 요청 헤더 지정]
        let header : HTTPHeaders = [
            "Authorization": KeyChain.shared.read(account: .accessToken),
            "Content-Type" : "application/json"
        ]
        // [http 요청 파라미터 지정 실시]
        let bodyData : Parameters = [
            "nickname" : nickName
        ]
        
        AF.request(
            url, // [주소]
            method: .post, // [전송 타입]
            parameters: bodyData, // [전송 데이터]
            encoding: JSONEncoding.default, // [인코딩 스타일]
            headers: header // [헤더 지정]
        )
        .validate(statusCode: 200..<300)
        .responseData { response in
            switch response.result {
            case .success(let res):
                do {
                    let decoder = JSONDecoder()
                    guard let decodedData = try? decoder.decode(ReviewResult.self, from: res) else {
                        print("catch")
                        return
                    }
                    completion(decodedData)
                    // [비동기 작업 수행]
                    DispatchQueue.main.async {
                    }
                }
                catch (let err){
                    print("catch :: ", err.localizedDescription)
                }
                break
            case .failure(let err):
                print("응답 코드 :: ", response.response?.statusCode ?? 0)
                print("에 러 :: ", err.localizedDescription)
                break
            }
        }
    }
    
    func sendComment(comment: String, id: Int,completion: @escaping (_ data: DefaultReturnID) -> Void){
        print(#function)
        // [http 요청 주소 지정]
        let url = "https://api.rec1pe.store:443/api/v1/comments/shortform/\(id)"
        // [http 요청 헤더 지정]
        let header : HTTPHeaders = [
            "Authorization": KeyChain.shared.read(account: .accessToken),
            "Content-Type" : "application/json"
        ]
        // [http 요청 파라미터 지정 실시]
        let bodyData : Parameters = [
            "content" : comment
        ]
        
        AF.request(
            url, // [주소]
            method: .post, // [전송 타입]
            parameters: bodyData, // [전송 데이터]
            encoding: JSONEncoding.default, // [인코딩 스타일]
            headers: header // [헤더 지정]
        )
        .validate(statusCode: 200..<300)
        .responseData { response in
            switch response.result {
            case .success(let res):
                do {
                    let decoder = JSONDecoder()
                    guard let decodedData = try? decoder.decode(DefaultReturnID.self, from: res) else {
                        print("catch")
                        return
                    }
                    completion(decodedData)
                    // [비동기 작업 수행]
                    DispatchQueue.main.async {
                    }
                }
                catch (let err){
                    print("catch :: ", err.localizedDescription)
                }
                break
            case .failure(let err):
                print("응답 코드 :: ", response.response?.statusCode ?? 0)
                print("에 러 :: ", err.localizedDescription)
                break
            }
        }
    }
    
    func sendCommentForRecipe(comment: String, id: Int,completion: @escaping (_ data: DefaultReturnID) -> Void){
        print(#function)
        // [http 요청 주소 지정]
        let url = "https://api.rec1pe.store:443/api/v1/comments/recipe/\(id)"
        // [http 요청 헤더 지정]
        let header : HTTPHeaders = [
            "Authorization": KeyChain.shared.read(account: .accessToken),
            "Content-Type" : "application/json"
        ]
        // [http 요청 파라미터 지정 실시]
        let bodyData : Parameters = [
            "content" : comment
        ]
        
        AF.request(
            url, // [주소]
            method: .post, // [전송 타입]
            parameters: bodyData, // [전송 데이터]
            encoding: JSONEncoding.default, // [인코딩 스타일]
            headers: header // [헤더 지정]
        )
        .validate(statusCode: 200..<300)
        .responseData { response in
            switch response.result {
            case .success(let res):
                do {
                    let decoder = JSONDecoder()
                    guard let decodedData = try? decoder.decode(DefaultReturnID.self, from: res) else {
                        print("catch")
                        return
                    }
                    completion(decodedData)
                    // [비동기 작업 수행]
                    DispatchQueue.main.async {
                    }
                }
                catch (let err){
                    print("catch :: ", err.localizedDescription)
                }
                break
            case .failure(let err):
                print("응답 코드 :: ", response.response?.statusCode ?? 0)
                print("에 러 :: ", err.localizedDescription)
                break
            }
        }
    }
    
    func sendRequest<T: Codable>(
        url: String,
        method: Alamofire.HTTPMethod = .post,
        parameters: Parameters? = nil,
        completion: @escaping (_ data: T) -> Void
    ) {
        print(#function)
        let header : HTTPHeaders = [
            "Authorization": KeyChain.shared.read(account: .accessToken),
            "Content-Type" : "application/json"
        ]
        
        AF.request(
            url,
            method: method,
            parameters: parameters,
            encoding: JSONEncoding.default,
            headers: header
        )
        .validate(statusCode: 200..<300)
        .responseData { response in
            switch response.result {
            case .success(let res):
                do {
                    let decoder = JSONDecoder()
                    guard let decodedData = try? decoder.decode(T.self, from: res) else {
                        print("Failed to decode response data")
                        return
                    }
                    completion(decodedData)
                }
                catch (let err) {
                    print("Decoding error :: ", err.localizedDescription)
                }
            case .failure(let err):
                print("Response code :: ", response.response?.statusCode ?? 0)
                print("Error :: ", err.localizedDescription)
            }
        }
    }
    
}
