//
//  MyPageView.swift
//  Recipe
//
//  Created by 김민호 on 2023/08/11.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

protocol MyPageViewDelegate: AnyObject {
    func favoriteReceipeButtonTapped(item: Recipe1?)
    func writeRecipeButtonTapped(item: Recipe1?)
    func myReviewButtonTapped()
    func recentShortFormCellTapped(item: ShortFormInfo)
    func recentRecipeCellTapped(item: RecipeInfo)
    func sendMyInfo(_ item: MyInfo1)
}

class MyPageView: UIView {
    
    enum Section: Hashable {
        case header
        case recentShortForm
        case recentRecipe
    }
    
    enum Item: Hashable {
        case header(MyInfo1)
        case recentShortForm(ShortFormInfo)
        case recentRecipe(RecipeInfo)
    }
    
    typealias Datasource = UICollectionViewDiffableDataSource<Section, Item>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Item>
    
    lazy var collectionView: UICollectionView = {
        let v = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        v.showsVerticalScrollIndicator = false
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .gray  // 로딩 인디케이터의 색상 설정
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    weak var delegate: MyPageViewDelegate?
    var viewModel: MyPageViewModel? {
        didSet {
            Task {
                await setViewModel()
            }
        }
    }
    private let disposeBag = DisposeBag()
    private var dataSource: Datasource!
    private var mockHeader2: MyInfo1 = MyInfo1(data: MyDetailInfo(memberId: 0, email: "", nickname: "", provider: "apple"))
    private var mockRecentShortForm: [ShortFormInfo] = []
    private var mockRecentRecipe: [RecipeInfo] = []
    
    private var favoriteRecipe: Recipe1?
    private var writeRecipe: Recipe1?
    var recentShortFormRelay = PublishRelay<[ShortFormInfoEntity]>()
    var recentRecipeForRelay = PublishRelay<[NewRecipeInfoEntity]>()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(collectionView)
        addSubview(loadingIndicator)  // 로딩 인디케이터 추가
        loadingIndicator.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
        showLoadingIndicator()
        configureLayout()
        registerCell()
        configureDataSource()
        collectionView.delegate = self
        
        recentShortFormRelay.subscribe(onNext: { value in
            
            self.mockRecentShortForm = value.map { ShortFormInfo(from: $0) }
            self.hideLoadingIndicator()
            self.dataSource.apply(self.createSnapshot(), animatingDifferences: true)
        }).disposed(by: disposeBag)
        
        recentRecipeForRelay.subscribe(onNext: { value in
            self.showLoadingIndicator()
            self.mockRecentRecipe = value.map { RecipeInfo(from: $0) }
            self.dataSource.apply(self.createSnapshot(), animatingDifferences: true)
            self.hideLoadingIndicator()
        }).disposed(by: disposeBag)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

//MARK: - Method(Normal)
extension MyPageView {
    
    func showLoadingIndicator() {
        loadingIndicator.startAnimating()
    }

    func hideLoadingIndicator() {
        loadingIndicator.stopAnimating()
    }
    
    func configureLayout() {
        collectionView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
//        collectionView.isScrollEnabled = false
    }
    func registerCell() {
        collectionView.registerCell(cellType: MyPageHeaderView.self)
        collectionView.registerCell(cellType: MyPageRecentWatchCell.self)
        collectionView.registerCell(cellType: IngredientRecipeCell.self)
        collectionView.registerHeaderView(viewType: MyPageTitleHeader.self)
    }
    
    func setViewModel() async {
        if let viewModel {
            print("")
            do {
                // Fetch MyInfo1
                let myInfo = try await viewModel.getMyInfo()
                self.delegate?.sendMyInfo(myInfo)
                mockHeader2 = myInfo
                dataSource.apply(createSnapshot(), animatingDifferences: true)

                // Fetch Recipe
                let recipe: Recipe1 = try await viewModel.get(.mySaveRecipeSearch)
                print("RECIPE:", recipe)
                self.favoriteRecipe = recipe
                
                // Fetch Written Recipe
                let writeRecipe: Recipe1 = try await viewModel.get(.myWrittenRecipeSearch)
                print("RECIPE:", recipe)
                self.writeRecipe = writeRecipe
                
            } catch {
                print("Error fetching data:", error)
            }
        }
    }

}

//MARK: Comp + Diff
extension MyPageView {
    func createLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { [unowned self] index, env in
            return self.sectionFor(index: index, environment: env)
        }
    }
    
    func sectionFor(index: Int, environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        
        let section = dataSource.snapshot().sectionIdentifiers[index]
        switch section {
        case .header:
            return createHeaderSection()
        case .recentShortForm:
            return createShortsSection()
        case .recentRecipe:
            return createRecipeSection()
            
        }
    }
    
    func createHeaderSection() -> NSCollectionLayoutSection {
        let headerItem = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0)))
        let headerGroup = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(280)), subitems: [headerItem])
        return NSCollectionLayoutSection(group: headerGroup)
    }

    
    func createShortsSection() -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1)))
        item.contentInsets = .init(top: 0, leading: 0, bottom: 0, trailing: 20)
        
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: .init(widthDimension: .fractionalWidth(0.9), heightDimension: .fractionalHeight(0.25)), subitem: item, count: 3)
        
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 10, trailing: 0)
        section.orthogonalScrollingBehavior = .continuous
        
        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(35))
        
        let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
        
        section.boundarySupplementaryItems = [header]
        return section
    }
    
    func createRecipeSection() -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1)))
        item.contentInsets = .init(top: 0, leading: 0, bottom: 0, trailing: 20)
        
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(200)), subitem: item, count: 2)
        // 183 109
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 50, trailing: 0)
        section.orthogonalScrollingBehavior = .continuous
        
        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(35))
        
        let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
        
        section.boundarySupplementaryItems = [header]
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
        case .header(let data):
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MyPageHeaderView.reuseIdentifier, for: indexPath) as! MyPageHeaderView
            cell.configure(data)
            cell.favoriteRecipeButton.rx.tap
                .subscribe(onNext: { _ in
                    self.delegate?.favoriteReceipeButtonTapped(item: self.favoriteRecipe)
                }).disposed(by: disposeBag)
            cell.myReviewRecipeButton.rx.tap
                .subscribe(onNext: { _ in
                    self.delegate?.myReviewButtonTapped()
                }).disposed(by: disposeBag)
            cell.writeRecipeButton.rx.tap
                .subscribe(onNext: { _ in
                    self.delegate?.writeRecipeButtonTapped(item: self.writeRecipe)
                }).disposed(by: disposeBag)
            return cell
            
        case .recentShortForm(let data):
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MyPageRecentWatchCell.reuseIdentifier, for: indexPath) as! MyPageRecentWatchCell
            cell.configure(data)
            return cell
            
        case .recentRecipe(let data):
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: IngredientRecipeCell.reuseIdentifier, for: indexPath) as! IngredientRecipeCell
            cell.configureForMyPage(data)
            return cell
            
        }
    }
    
    private func supplementary(collectionView: UICollectionView, kind: String, indexPath: IndexPath, section: Section) -> UICollectionReusableView {
        let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: MyPageTitleHeader.identifier, for: indexPath) as! MyPageTitleHeader
        switch section {
        case .recentShortForm:
            headerView.configure("최근에 시청한 숏폼")
            return headerView
        case .recentRecipe:
            headerView.configure("최근에 본 레시피")
            return headerView
        default: return UICollectionReusableView()
            
        }
    }
    
    private func createSnapshot() -> Snapshot{
        var snapshot = Snapshot()
        snapshot.appendSections([.header, .recentShortForm, .recentRecipe])
        snapshot.appendItems([.header(mockHeader2)], toSection: .header)
        snapshot.appendItems(mockRecentShortForm.map({ Item.recentShortForm($0) }), toSection: .recentShortForm)
        snapshot.appendItems(mockRecentRecipe.map({ Item.recentRecipe($0) }), toSection: .recentRecipe)
        
        return snapshot
    }
}

extension MyPageView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        
        switch item {
        case .recentShortForm(let data):
            delegate?.recentShortFormCellTapped(item: data)
        case .recentRecipe(let data):
            delegate?.recentRecipeCellTapped(item: data)
        default:
            break
        }
    }
}

#if DEBUG
import SwiftUI
struct ForMyPageView: UIViewRepresentable {
    typealias UIViewType = UIView
    
    func makeUIView(context: Context) -> UIView {
        MyPageView()
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
    }
}

@available(iOS 13.0, *)
struct MyPageView_Preview: PreviewProvider {
    static var previews: some View {
        ForMyPageView()
//            .ignoresSafeArea()
    }
}
#endif
