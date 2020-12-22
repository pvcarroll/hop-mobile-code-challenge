//
//  PhotoGalleryViewModel.swift
//  PhotoGallery
//
//  Created by Paul Carroll on 12/18/20.
//

import Foundation
import Combine
import SwiftUI

class PhotoGalleryViewModel: ObservableObject {
    private let apiService: ServiceProtocol
    @Published var photos = [Photo]()
    @Published var networkError: APIError?
    
    var cancellables = Set<AnyCancellable>()
    
    init(apiService: ServiceProtocol) {
        self.apiService = apiService
    }
    
    func getPhotos() {
        let urlRequest = PhotoGalleryEndpoint.photos.urlRequest
        let cancellable = apiService.request(with: urlRequest)
            .sink(receiveCompletion: { result in
                switch result {
                case .failure(let error):
                    self.networkError = error
                case .finished:
                    break
                }
            }) {
                self.photos = $0
            }
        cancellables.insert(cancellable)
    }
}