//
//  ShortFormViewController.swift
//  Recipe
//
//  Created by 김민호 on 2023/08/01.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit
import UPCarouselFlowLayout
import AVFoundation

final class ShortFormViewController: BaseViewController {
    
    ///UI Properties
    private let searchTextField: PaddingUITextField = {
        let v = PaddingUITextField()
        v.textPadding = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        v.backgroundColor = .gray.withAlphaComponent(0.2)
        v.placeholder = "레시피 및 재료를 검색해보세요."
        v.layer.cornerRadius = 10
        v.clipsToBounds = true
        return v
    }()
    
    private let searchImageButton: UIButton = {
        let v = UIButton()
        let img = v.buttonImageSize(systemImageName: "magnifyingglass", size: 25)
        v.setImage(img, for: .normal)
        v.contentMode = .scaleAspectFit
        v.tintColor = UIColor.hexStringToUIColor(hex: "#FF5520")
        return v
    }()
    
    var didSendEventClosure: ((ShortFormViewController.Event) -> Void)?
    var disposeBag = DisposeBag()
    lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: aa())
    private let video: [String] = [
        "https://storage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
        "https://storage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
        "https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4",
        "https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4",
        "https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4",
        "https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyrides.mp4",
        "https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerMeltdowns.mp4",
        "https://storage.googleapis.com/gtv-videos-bucket/sample/SubaruOutbackOnStreetAndDirt.mp4",
        "https://storage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4"
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubViews(collectionView, searchTextField, searchImageButton)
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(ShortFormCell.self, forCellWithReuseIdentifier: ShortFormCell.reuseIdentifier)
        configureLayout()
        configureNavigationTabBar()
        collectionView.reloadData()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        disposeBag = DisposeBag()
    }
    
    enum Event {
        case go
    }
}

//MARK: - Method(Normal)
extension ShortFormViewController {
    
    func configureLayout() {
        searchTextField.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(10)
            $0.left.right.equalToSuperview().inset(20)
            $0.height.equalTo(51.57)
        }
        
        searchImageButton.snp.makeConstraints {
            $0.right.equalTo(searchTextField).inset(15)
            $0.centerY.equalTo(searchTextField)
        }
        
        collectionView.snp.makeConstraints {
            $0.top.equalTo(searchTextField.snp.bottom).offset(10)
            $0.left.right.equalToSuperview()
            $0.bottom.equalToSuperview().inset(30)
        }
    }
    
    private func configureNavigationTabBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem.menuButton(imageName: "bell.hasAlert")
        navigationItem.leftBarButtonItem = UIBarButtonItem.menuButtonWithLabel(imageName: "logo", size: CGSize(width: 90, height: 50))
        navigationController?.navigationBar.barTintColor = .white
    }
    
    func aa() -> UICollectionViewFlowLayout {
        let layout = UPCarouselFlowLayout()
        layout.sideItemScale = 0.7
        layout.spacingMode = .fixed(spacing: 15)
//        layout.spacingMode = .fixed(spacing: 50)
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSizeMake(view.frame.width * 0.8, view.frame.height * 0.6)
        return layout
    }
    
}

//MARK: - CollectionView Delegate
extension ShortFormViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return video.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ShortFormCell.reuseIdentifier, for: indexPath) as! ShortFormCell
        //        print(collectionView.indexPathsForSelectedItems)
        //        if cell == collectionView.visibleCells.first {
        //            print("yes!")
        //            cell.playVideo(url: video[indexPath.row])
        //        }
//        if indexPath.row == 0 {
//            cell.playVideo(url: video[0])
//        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? ShortFormCell {
            cell.playVideo(url: video[indexPath.row])
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? ShortFormCell {
            cell.stop()
        }
    }
}

//MARK: - VC Preview
import SwiftUI
struct ShortFormViewController_preview: PreviewProvider {
    static var previews: some View {
        
        UINavigationController(rootViewController: ShortFormViewController())
            .toPreview()
            .previewDevice(PreviewDevice(rawValue: "iPhone 12"))
    }
}
