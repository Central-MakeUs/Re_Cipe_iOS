//
//  CreateRecipeView.swift
//  Recipe
//
//  Created by 김민호 on 2023/07/14.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

struct Dummy: Hashable {
    let id = UUID()
    let contents: String
    let img: UIImage?
}

protocol CreateRecipeViewDelegate: AnyObject {
    func registerButtonTapped()
    func addPhotoButtonTapped()
}
final class CreateRecipeView: UIView {
    enum Section: Hashable {
        case thumbnailSection
        case recipeNameSection
        case recipeDescriptSection
        case recipeIngredientSection
        case cookTimeSettingSection
        case cookStepSection
    }
    
    enum Item: Hashable {
        case thumbnailSection
        case recipeNameSection
        case recipeDiscriptSection
        case recipeIngredientSection
        case cookTimeSettingSection
        case cookStepSection(Dummy)
    }
    
    enum A: Hashable {
        case cookStepSection(Dummy)
    }
    
    typealias Datasource = UICollectionViewDiffableDataSource<Section, Item>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Item>
    
    /// UI Properties
    lazy var collectionView: UICollectionView = {
        let v = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        v.showsVerticalScrollIndicator = false
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let registerButton: UIButton = {
        let v = UIButton()
        v.setTitle("등록", for: .normal)
        v.setTitleColor(.white, for: .normal)
        v.backgroundColor = .grayScale3
        v.layer.cornerRadius = 10
        v.clipsToBounds = true
        return v
    }()
    
    /// Properties
    private var dataSource: Datasource!
    private let disposeBag = DisposeBag()
    weak var delegate: CreateRecipeViewDelegate?
    private var mockData: [Dummy] = [Dummy(contents: "", img: UIImage())]
    let imageRelay = PublishRelay<UIImage>()
    let imageBehaviorRelay = BehaviorRelay<UIImage>(value: UIImage())
    var mybool = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addView()
        configureLayout()
        registerCell()
        configureDataSource()
        dataSource.reorderingHandlers.canReorderItem = { item in
            return true
        }
        
        dataSource.reorderingHandlers.didReorder = { [weak self] transaction in
            guard let self = self else { return }
            for sectionTransaction in transaction.sectionTransactions {
                let sectionIdentifier = sectionTransaction.sectionIdentifier
                switch sectionIdentifier {
                case .cookStepSection:
                    var myData = [Dummy]()
                    for a in sectionTransaction.finalSnapshot.items {
                        switch a {
                        case .cookStepSection(let data):
                            myData.append(data)
                        default:
                            return
                        }
                    }
                    self.mockData = myData
                default:
                    return
                    
                }
            }
        }
        
        collectionView.delegate = self
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    
}

//MARK: - Method(Normal)
extension CreateRecipeView {
    
    func addView() {
        addSubViews(collectionView, registerButton)
    }
    
    func configureLayout() {
        collectionView.snp.makeConstraints {
            $0.top.equalTo(self.safeAreaLayoutGuide)
            $0.left.right.equalToSuperview()
            $0.bottom.equalTo(registerButton.snp.top)
        }
        
        registerButton.snp.makeConstraints {
            $0.left.right.equalToSuperview().inset(10)
            $0.height.equalTo(50) // 버튼 높이 설정
            $0.bottom.equalTo(self.safeAreaLayoutGuide).inset(10)
        }
    }
    
    func registerCell() {
        collectionView.registerCell(cellType: CreateRecipeHeaderCell.self)
        collectionView.registerCell(cellType: TextFieldCell.self)
        collectionView.registerCell(cellType: TextFieldViewCell.self)
        collectionView.registerCell(cellType: CookSettingCell.self)
        collectionView.registerCell(cellType: DefaultTextFieldCell.self)
        collectionView.registerCell(cellType: CookStepCell.self)
        collectionView.registerCell(cellType: CookStepCell2.self)
        
        collectionView.registerHeaderView(viewType: DefaultHeader.self)
        collectionView.registerHeaderView(viewType: CookStepHeaderView.self)
        collectionView.registerHeaderView(viewType: CookStepCountCell.self)
        
//        collectionView.registerFooterView(viewType: CreateRecipeFooter.self)
        collectionView.registerFooterView(viewType: CookStepFooterView.self)
    }
    
    private func makeSwipeActions(for indexPath: IndexPath?) -> UISwipeActionsConfiguration? {
        guard let indexPath = indexPath, let id = dataSource.itemIdentifier(for: indexPath) else { return nil }
        let deleteActionTitle = NSLocalizedString("Delete", comment: "Delete action title")
        let deleteAction = UIContextualAction(style: .destructive, title: deleteActionTitle) { [weak self] a, b, completion in
            print("id:", id)
            self?.deleteItem(id, idx: indexPath)
            completion(false)
        }
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
    
    private func deleteItem(_ item: Item, idx: IndexPath) {
        guard case let .cookStepSection(dummyData) = item else { return }
        var snapShot = dataSource.snapshot()
        snapShot.deleteItems([item])
        
        if let index = mockData.firstIndex(of: dummyData) {
            mockData.remove(at: index)
        }
        dataSource.apply(snapShot, animatingDifferences: true)
        applyNewSnapshot()
    }
    
    /// 조리단계의 리스트 셀을 추가하거나 삭제할 때 헤더의 카운트를 조절 하는 함수 입니다.
    private func applyNewSnapshot() {
        print(#function)
        var newSnapshot = self.dataSource.snapshot()
        if #available(iOS 15.0, *) {
            self.dataSource.applySnapshotUsingReloadData(newSnapshot)
        } else {
            newSnapshot.reloadSections([.cookStepSection])
            self.dataSource.apply(newSnapshot, animatingDifferences: false)
        }
    }
}
//MARK: Comp + Diff
extension CreateRecipeView {
    func createLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { [unowned self] index, env in
            let section = dataSource.snapshot().sectionIdentifiers[index]
            switch section {
            case .cookStepSection:
                var configuration = UICollectionLayoutListConfiguration(appearance: .plain)
                configuration.headerMode = .supplementary
//                configuration.footerMode = .supplementary
                configuration.trailingSwipeActionsConfigurationProvider = makeSwipeActions
                configuration.showsSeparators = false
                
                
                let section = NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: env)
                section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
                section.interGroupSpacing = 10
                return section
            default:
                return self.sectionFor(index: index, environment: env)
            }
        }
    }
    
    func sectionFor(index: Int, environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        
        let section = dataSource.snapshot().sectionIdentifiers[index]
        switch section {
        case .thumbnailSection:
            return createThumbnailSection()
        case .recipeNameSection, .cookTimeSettingSection:
            return createEqualSize()
        case .recipeIngredientSection:
            return createIngredientSection()
        case .recipeDescriptSection:
            return createRecipeDescription()
        case .cookStepSection:
            return createCookStepSection()
        }
    }
    
    func createRecipeDescription() -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .fractionalHeight(1)))
        item.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 3, trailing: 10)
        
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .absolute(100)),
            subitem: item,
            count: 1)
        
        let section = NSCollectionLayoutSection(group: group)
        
        let footerHeaderSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                      heightDimension: .absolute(50.0))
        let header = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: footerHeaderSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .topLeading)
        section.boundarySupplementaryItems = [header]
        section.orthogonalScrollingBehavior = .groupPaging
        
        
        // Return
        return section
    }
    
    func createThumbnailSection() -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .fractionalHeight(1)))
        item.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 3, trailing: 10)
        
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .fractionalHeight(0.25)),
            subitem: item,
            count: 1)
        
        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .none
        
        
        // Return
        return section
    }
    
    func createEqualSize() -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .fractionalHeight(1)))
        item.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 3, trailing: 10)
        
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .absolute(60)),
            subitem: item,
            count: 1)
        
        let section = NSCollectionLayoutSection(group: group)
        
        let footerHeaderSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                      heightDimension: .absolute(50.0))
        let header = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: footerHeaderSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .topLeading)
        section.boundarySupplementaryItems = [header]
        section.orthogonalScrollingBehavior = .groupPaging
        
        
        // Return
        return section
    }
    
    func calculateSectionHeight() -> CGFloat {
        return mybool ? 100 : 50
    }
    
    
    func createIngredientSection() -> NSCollectionLayoutSection {
        let sectionHeight = self.calculateSectionHeight()
        
        let item = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .estimated(sectionHeight)))
        //        item.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 3, trailing: 10)
        
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .estimated(sectionHeight)),
            subitem: item,
            count: 1)
        group.interItemSpacing = .fixed(10)
        let section = NSCollectionLayoutSection(group: group)
        
        let footerHeaderSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                      heightDimension: .absolute(50.0))
        let header = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: footerHeaderSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .topLeading)
        section.boundarySupplementaryItems = [header]
        section.orthogonalScrollingBehavior = .groupPaging
        
        // Return
        return section
    }
    
    func createCookStepSection() -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .fractionalHeight(0.1)))
        item.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 3, trailing: 10)
        
        let group = NSCollectionLayoutGroup.vertical(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .fractionalHeight(0.7)),
            subitems: [item])
        
        //        let grups = NSCollectionLayoutGroup.
        //        ,
        //            count: mockData.count)
        
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        let footerHeaderSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                      heightDimension: .absolute(50.0))
        let header = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: footerHeaderSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .topLeading)
        
//        let footer = NSCollectionLayoutBoundarySupplementaryItem(
//            layoutSize: footerHeaderSize,
//            elementKind: UICollectionView.elementKindSectionFooter,
//            alignment: .bottom)
        
        section.boundarySupplementaryItems = [header]
        section.orthogonalScrollingBehavior = .groupPaging
        
        
        // Return
        return section
    }
    
    
    private func configureDataSource() {
        dataSource = Datasource(collectionView: collectionView) { (collectionView, indexPath, item) -> UICollectionViewCell? in
            return self.cell(collectionView: collectionView, indexPath: indexPath, item: item)}
        
        dataSource.supplementaryViewProvider = { [unowned self] collectionView, kind, indexPath in
            let section = self.dataSource.snapshot().sectionIdentifiers[indexPath.section]
            return self.supplementary(collectionView: collectionView, kind: kind, indexPath: indexPath, section: section)
        }
        
        dataSource.apply(createSnapshot(), animatingDifferences: true)
    }
    
    private func cell(collectionView: UICollectionView, indexPath: IndexPath, item: Item) -> UICollectionViewCell{
        switch item {
        case .thumbnailSection:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CreateRecipeHeaderCell.reuseIdentifier, for: indexPath) as! CreateRecipeHeaderCell
            return cell
        case .recipeNameSection:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TextFieldCell.reuseIdentifier, for: indexPath) as! TextFieldCell
            cell.configure(text: "레시피 이름을 입력해주세요", needSearchButton: false)
            return cell
        case .recipeDiscriptSection:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TextFieldViewCell.reuseIdentifier, for: indexPath) as! TextFieldViewCell
            return cell
        case .recipeIngredientSection:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DefaultTextFieldCell.reuseIdentifier, for: indexPath) as! DefaultTextFieldCell
            cell.configure(text: "재료 및 양념을 입력해주세요.")
            cell.recipeNametextField.rx.text.orEmpty
                .debounce(.seconds(1), scheduler: MainScheduler.instance)
                .subscribe(onNext: { txt in
                    if cell.filteredData.isEmpty {
                        self.mybool = false
                    } else {
                        self.mybool = true
                    }
                    self.collectionView.collectionViewLayout.invalidateLayout()
                    self.collectionView.layoutIfNeeded()
                }).disposed(by: disposeBag)
            return cell
        case .cookTimeSettingSection:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CookSettingCell.reuseIdentifier, for: indexPath) as! CookSettingCell
            return cell
        case .cookStepSection(let data):
            if data.contents == "" {
                // Show a different cell when the array is empty
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CookStepCell2.reuseIdentifier, for: indexPath) as! CookStepCell2
                imageRelay.subscribe(onNext: { data in
                    cell.imageSelectSubject.accept(data)
                }).disposed(by: disposeBag)
                
                cell.addPhotoButton.rx.tap
                    .subscribe(onNext: { _ in
                        self.delegate?.addPhotoButtonTapped()
                    }).disposed(by: disposeBag)
                
                cell.stepTextfield.rx.controlEvent(.editingDidEndOnExit)
                    .subscribe(onNext: { [weak self, weak cell] _ in
                        guard let self = self, let cell = cell, let newText = cell.stepTextfield.text else { return }
                        if newText.isEmpty {
                            // Skip empty text
                            return
                        }
                        let defaultImage = UIImage(named: "popcat")
                        let newStep = Dummy(contents: newText, img: self.imageBehaviorRelay.value)
                        if !mockData.contains(newStep) {
                            self.mockData.insert(newStep, at: 0)
                            print(self.mockData)
                        }
                        //                        self.mockData.insert(newStep, at: 0)
                        self.dataSource.apply(self.createSnapshot(), animatingDifferences: true)
                        self.applyNewSnapshot()
                        cell.stepTextfield.text = ""
                        self.imageBehaviorRelay.accept(defaultImage!)
                        if let initialIndexPath = dataSource.indexPath(for: .cookStepSection(mockData.last!)) {
                            collectionView.scrollToItem(at: initialIndexPath, at: .bottom, animated: true)
                        }
                    }).disposed(by: cell.disposeBag)
                return cell
            } else {
                // Show the CookStepCell when the array has values
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CookStepCell.reuseIdentifier, for: indexPath) as! CookStepCell
                cell.accessories = [.reorder(displayed: .always), .delete()]
//                imageBehaviorRelay.subscribe(onNext: { data in
//                    cell.imageSelectSubject.accept(data)
//                }).disposed(by: disposeBag)
                
                cell.addPhotoButton.rx.tap
                    .subscribe(onNext: { _ in
                        self.delegate?.addPhotoButtonTapped()
                    }).disposed(by: disposeBag)
                
                cell.defaultCheck.accept(false)
                cell.configure(data)
                print(data)
                return cell
            }
        }
    }
    
    private func supplementary(collectionView: UICollectionView, kind: String, indexPath: IndexPath, section: Section) -> UICollectionReusableView {
        switch section {
        case .thumbnailSection:
            return UICollectionReusableView()
        case .recipeNameSection:
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: DefaultHeader.identifier, for: indexPath) as! DefaultHeader
            headerView.configureTitle(text: "레시피 이름")
            return headerView
        case .recipeDescriptSection:
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: DefaultHeader.identifier, for: indexPath) as! DefaultHeader
            headerView.configureTitle(text: "레시피 설명")
            return headerView
        case .recipeIngredientSection:
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: DefaultHeader.identifier, for: indexPath) as! DefaultHeader
            headerView.configureTitle(text: "재료/양념")
            return headerView
        case .cookTimeSettingSection:
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: CookStepHeaderView.identifier, for: indexPath) as! CookStepHeaderView
            //            headerView.configureTitle(text: "조리 시간 분")
            headerView.configureDoubleTitle(text: "조리시간", text2: "인분")
            //            headerView.highlightTextColor()
            return headerView
        case .cookStepSection:
//            if kind == UICollectionView.elementKindSectionHeader {
                let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: CookStepCountCell.identifier, for: indexPath) as! CookStepCountCell
                headerView.configureTitleCount(text: "조리 단계", count: mockData.count - 1)
                return headerView
//            } else {
//                let footerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: CookStepFooterView.identifier, for: indexPath) as! CookStepFooterView
//                //                footerView.registerButton.rx.tap
//                //                    .subscribe(onNext: { _ in
//                //                        self.delegate?.registerButtonTapped()
//                //                    }).disposed(by: disposeBag)
//                return footerView
//            }
            
        }
    }
    
    private func createSnapshot() -> Snapshot{
        var snapshot = Snapshot()
        snapshot.appendSections([.thumbnailSection, .recipeNameSection, .recipeDescriptSection, .recipeIngredientSection ,.cookTimeSettingSection, .cookStepSection])
        snapshot.appendItems([.thumbnailSection], toSection: .thumbnailSection)
        snapshot.appendItems([.recipeNameSection], toSection: .recipeNameSection)
        snapshot.appendItems([.recipeDiscriptSection], toSection: .recipeDescriptSection)
        snapshot.appendItems([.recipeIngredientSection], toSection: .recipeIngredientSection)
        snapshot.appendItems([.cookTimeSettingSection], toSection: .cookTimeSettingSection)
        snapshot.appendItems(mockData.map { Item.cookStepSection($0)}, toSection: .cookStepSection)
        
        return snapshot
    }
}

//MARK: - Method(Rx Bind)


extension CreateRecipeView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, targetIndexPathForMoveFromItemAt originalIndexPath: IndexPath, toProposedIndexPath proposedIndexPath: IndexPath) -> IndexPath {
        if originalIndexPath.section != proposedIndexPath.section {
            return originalIndexPath
        }
        return proposedIndexPath
    }
}

import SwiftUI
struct ForNewCreateRecipeView: UIViewRepresentable {
    typealias UIViewType = UIView
    
    func makeUIView(context: Context) -> UIView {
        CreateRecipeView()
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
    }
}

@available(iOS 13.0, *)
struct NewCreateRecipeView_Preview: PreviewProvider {
    static var previews: some View {
        ForNewCreateRecipeView()
    }
}
