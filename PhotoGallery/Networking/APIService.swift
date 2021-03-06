//
//  APIService.swift
//  PhotoGallery
//
//  Created by Paul Carroll on 12/18/20.
//

import Foundation
import Combine

protocol ServiceProtocol {
    func request<T>(with urlRequest: URLRequest) -> AnyPublisher<T, APIError> where T: Decodable
    func request(with urlRequest: URLRequest) -> AnyPublisher<URLSession.DataTaskPublisher.Output, URLError>
}

struct APIService: ServiceProtocol {

    static let instance = APIService()
    
    func request<T>(with urlRequest: URLRequest) -> AnyPublisher<T, APIError> where T: Decodable {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        return URLSession.shared
            .dataTaskPublisher(for: urlRequest)
            .receive(on: DispatchQueue.main)
            .mapError { _ in .unknown }
            .flatMap { data, response -> AnyPublisher<T, APIError> in
                if let response = response as? HTTPURLResponse {
                    if (200...299).contains(response.statusCode) {
                        return Just(data)
                            .decode(type: T.self, decoder: decoder)
                            .mapError { _ in .decodingError }
                            .eraseToAnyPublisher()
                    } else {
                        return Fail(error: APIError.httpError(response.statusCode))
                            .eraseToAnyPublisher()
                    }
                }
                return Fail(error: APIError.unknown)
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    func request(with urlRequest: URLRequest) -> AnyPublisher<URLSession.DataTaskPublisher.Output, URLError> {
        return URLSession.shared
            .dataTaskPublisher(for: urlRequest)
            .eraseToAnyPublisher()
    }
}

struct MockAPIService: ServiceProtocol {
    var data: Data
    
    init(data: Data) {
        self.data = data
    }

    func request<T>(with urlRequest: URLRequest) -> AnyPublisher<T, APIError> where T : Decodable {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return Just(data)
            .decode(type: T.self, decoder: decoder)
            .mapError { _ in .decodingError }
            .eraseToAnyPublisher()
    }
    
    func request(with urlRequest: URLRequest) -> AnyPublisher<URLSession.DataTaskPublisher.Output, URLError> {
        guard let url = urlRequest.url else { preconditionFailure("URLRequest.url is nil") }
        guard let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: nil)
            else { preconditionFailure("Failed to create HTTPURLResponse") }
        return Just((data: data, response: response))
            .setFailureType(to: URLError.self)
            .eraseToAnyPublisher()
    }
}
