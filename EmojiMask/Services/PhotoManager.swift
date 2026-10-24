import UIKit
import Photos

public class PhotoManager {
    public static let shared = PhotoManager()

    private init() {}

    public func savePhotoToGallery(image: UIImage, completion: @escaping (Bool) -> Void) {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else {
                DispatchQueue.main.async { completion(false) }
                return
            }

            PHPhotoLibrary.shared().performChanges({
                let creationRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
                guard let assetPlaceholder = creationRequest.placeholderForCreatedAsset else { return }

                // Find or create "EmojiMask" album
                let fetchOptions = PHFetchOptions()
                fetchOptions.predicate = NSPredicate(format: "title = %@", "EmojiMask")
                let albumCollection = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)

                if let existingAlbum = albumCollection.firstObject {
                    let albumChangeRequest = PHAssetCollectionChangeRequest(for: existingAlbum)
                    albumChangeRequest?.addAssets([assetPlaceholder] as NSArray)
                } else {
                    let albumChangeRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: "EmojiMask")
                    albumChangeRequest.addAssets([assetPlaceholder] as NSArray)
                }
            }) { success, error in
                DispatchQueue.main.async {
                    completion(success && error == nil)
                }
            }
        }
    }
}
