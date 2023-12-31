//
//  RecipeView.swift
//  Recipe
//
//  Created by KindSoft on 2023/07/11.
//
import UIKit
import SnapKit
import RxSwift
import RxCocoa

protocol RecipeViewDelegate: AnyObject {
    func didTappedRecipeCell(item: RecipeInfo)
    func didTappedSortButton(_ tag: Int)
    func didTappedThemeButton(_ theme: Theme)
}

struct MockCategoryData: Hashable {
    let id = UUID()
    let text: String
    let img: UIImage
    let theme: Theme
}

enum Theme: String {
    case budgetHappiness = "BudgetHappiness"
    case forDieting = "ForDieting"
    case houseWarming = "Housewarming"
    case livingAlone = "LivingAlone"
}


final class RecipeView: UIView {
    enum Section: Hashable {
        case header
        case recipe
    }
    
    enum Item: Hashable {
        case header(MockCategoryData)
        case recipe(RecipeInfo)
    }
    
    typealias Datasource = UICollectionViewDiffableDataSource<Section, Item>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Item>
    
    ///UI Properties
    private let searchTextField: PaddingUITextField = {
        let v = PaddingUITextField()
        v.textPadding = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        v.backgroundColor = UIColor.hexStringToUIColor(hex: "F8F8F8")
        v.placeholder = "레시피 및 재료를 검색해보세요."
        v.layer.cornerRadius = 10
        v.clipsToBounds = true
        v.isEnabled = false
        return v
    }()
    
    let searchImageButton: UIButton = {
        let v = UIButton()
        let img = v.buttonImageSize(imageName: "search_svg", size: 24)
        v.setImage(img, for: .normal)
        v.contentMode = .scaleAspectFit
        v.tintColor = .mainColor
        return v
    }()
    
    lazy var collectionView: UICollectionView = {
        let v = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        v.showsVerticalScrollIndicator = false
        v.translatesAutoresizingMaskIntoConstraints = false
//        v.isScrollEnabled = false
        return v
    }()
    
    ///Properties
    var viewModel: RecipeViewModel? {
        didSet {
            Task {
                await setViewModel()
            }
        }
    }
    
    var myData = PublishRelay<[RecipeInfo]>()
    private let disposeBag = DisposeBag()
    weak var delegate: RecipeViewDelegate?
    private var dataSource: Datasource!
    private let mockCategoryData: [MockCategoryData] = [
        MockCategoryData(text: "자취생 필수!",img: UIImage(named: "homealone_svg")!,theme: .livingAlone),
        MockCategoryData(text: "다이어터를\n위한 레시피",img: UIImage(named: "diet_svg")!, theme: .forDieting),
        MockCategoryData(text: "알뜰살뜰\n만원의 행복",img: UIImage(named: "manwon_svg")!, theme: .budgetHappiness),
        MockCategoryData(text: "집들이용\n레시피",img: UIImage(named: "homeparty_svg")!, theme: .houseWarming)]
    
//    private var recipeList = [RecipeInfo]()
    private var recipeList = [RecipeInfo]()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubViews(searchTextField, searchImageButton, collectionView)
        configureLayout()
        registerCell()
        configureDataSource()
        collectionView.delegate = self
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}

//MARK: - Method(Normal)
extension RecipeView {
    func configureLayout() {
        searchTextField.snp.makeConstraints {
            $0.top.equalTo(self.safeAreaLayoutGuide).offset(10)
            $0.left.right.equalToSuperview().inset(20)
            $0.height.equalTo(51.57)
        }
        
        searchImageButton.snp.makeConstraints {
            $0.right.equalTo(searchTextField).inset(15)
            $0.centerY.equalTo(searchTextField)
        }
        
        collectionView.snp.makeConstraints {
            $0.top.equalTo(searchTextField.snp.bottom).offset(10)
            $0.left.right.bottom.equalToSuperview()
        }
    }
    
    private func registerCell() {
        collectionView.register(DefaultRecipeCategoryView.self, forCellWithReuseIdentifier: DefaultRecipeCategoryView.reuseIdentifier)
        collectionView.register(RecipeCell.self, forCellWithReuseIdentifier: RecipeCell.reuseIdentifier)
        collectionView.register(RecipeHeaderCell.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: RecipeHeaderCell.reuseIdentifier)
    }
    
    func setViewModel() async {
        if let viewModel {
            let a = try? await viewModel.getMyInfo(.latest)
            if let a {
                self.recipeList = []
                let contents = a.data.content
                var infoList: [RecipeInfo] = []
                for i in contents {
//                    i.recipe_id
                    do {
                        let data: RecipeDetail = try await NetworkManager.shared.get(.recipeDetail("\(i.recipe_id)"))
                        let writtenId = data.data.writtenid
//                        if data.data.writtenid
                        if UserReportHelper.shared.isUserIdInUserReports(userId: Int64(writtenId)) {
                            print("yes")
                        } else {
                            print("no..")
                            infoList.append(i)
                        }
                    } catch {
                        print("")
                    }
                }
                recipeList = infoList
                dataSource.apply(createSnapshot(), animatingDifferences: true)
            }
        }
    }
}

//MARK: Comp + Diff
extension RecipeView {
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
        case .recipe:
            return createRecipeSection()
        }
    }
    
    func createHeaderSection() -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(95)))
        item.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 14, bottom: 10, trailing: 14)
        
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(85)), subitem: item, count: 2)
        
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 15, trailing: 0)
//        section.orthogonalScrollingBehavior = .continuous
        return section
    }
    
    func createRecipeSection() -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(100)))
        item.contentInsets = .init(top: 0, leading: 0, bottom: 10, trailing: 0)
        
        let group = NSCollectionLayoutGroup.vertical(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .estimated(100)), subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 15, leading: 21, bottom: 10, trailing: 14)
        section.orthogonalScrollingBehavior = .continuous
        
        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(30))
        
        let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
        
        section.boundarySupplementaryItems = [header]
        section.orthogonalScrollingBehavior = .none
        return section
    }
    
    private func configureDataSource() {
        dataSource = Datasource(collectionView: collectionView) { (collectionView, indexPath, item) -> UICollectionViewCell? in
            return self.cell(collectionView: collectionView, indexPath: indexPath, item: item)}
        
        dataSource.supplementaryViewProvider = { [unowned self] collectionView, kind, indexPath in
            return self.supplementary(collectionView: collectionView, kind: kind, indexPath: indexPath)
        }
        
        dataSource.apply(createSnapshot(), animatingDifferences: true)
    }
    
    private func cell(collectionView: UICollectionView, indexPath: IndexPath, item: Item) -> UICollectionViewCell{
        switch item {
        case .header(let data):
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DefaultRecipeCategoryView.reuseIdentifier, for: indexPath) as! DefaultRecipeCategoryView
            cell.configureData(data)
            cell.backgroundButton.rx.tap
                .subscribe(onNext: { _ in
                    self.delegate?.didTappedThemeButton(data.theme)
                }).disposed(by: disposeBag)
            return cell
            
        case .recipe(let data):
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: RecipeCell.reuseIdentifier, for: indexPath) as! RecipeCell
            cell.configure(data)
            cell.favoriteButton.rx.tap
                .subscribe(onNext: { _ in
//                    indexPath.row
                    Task {
                        if data.is_saved {
                            let a: DeleteRecipeReuslt = try await NetworkManager.shared.get(.recipeUnSave("\(data.recipe_id)"), parameters: ["recipe-id": data.recipe_id])
                            if a.code == "SUCCESS" {
                                DispatchQueue.main.async {
                                    cell.favoriteButton.setImage(UIImage(named: "bookmark_svg")!, for: .normal)
                                }
                            }
                        } else {
                            let a: DeleteRecipeReuslt = try await NetworkManager.shared.get(.recipeSave("\(data.recipe_id)"), parameters: ["recipe-id": data.recipe_id])
                            
                            if a.code == "SUCCESS" {
                                DispatchQueue.main.async {
                                    cell.favoriteButton.setImage(UIImage(named: "bookmarkfill_svg")!, for: .normal)
                                }
                            }
                        }
                    }
                }).disposed(by: disposeBag)
            return cell
        }
    }
    
    private func supplementary(collectionView: UICollectionView, kind: String, indexPath: IndexPath) -> UICollectionReusableView {
        let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: RecipeHeaderCell.reuseIdentifier, for: indexPath) as! RecipeHeaderCell
        
        headerView
            .buttonTappedSubject
            .subscribe(onNext: { tagNumber in
                Task {
                    switch tagNumber {
                    case 0:
                        if let viewModel = self.viewModel {
                            let a = try? await viewModel.getMyInfo(.latest)
                            if let a {
                                self.recipeList = []
                                let contents = a.data.content
                                var infoList: [RecipeInfo] = []
                                for i in contents {
                                    if UserReportHelper.shared.isUserIdInUserReports(userId: Int64(i.writtenid)) {
                                        print("차단자 있음")
                                    } else {
                                        infoList.append(i)
                                    }
                                }
                                self.recipeList = infoList
                                self.dataSource.apply(self.createSnapshot(), animatingDifferences: true)
                            }
                        }
                    case 1:
                        if let viewModel = self.viewModel {
                            let a = try? await viewModel.getMyInfo(.popular)
                            if let a {
                                self.recipeList = []
                                let contents = a.data.content
                                var infoList: [RecipeInfo] = []
                                for i in contents {
                                    if UserReportHelper.shared.isUserIdInUserReports(userId: Int64(i.writtenid)) {
                                        print("차단자 있음")
                                    } else {
                                        infoList.append(i)
                                    }
                                }
                                self.recipeList = infoList
                                self.dataSource.apply(self.createSnapshot(), animatingDifferences: true)
                            }
                        }
                    case 2:
                        if let viewModel = self.viewModel {
                            let a = try? await viewModel.getMyInfo(.minium)
                            if let a {
                                self.recipeList = []
                                let contents = a.data.content
                                var infoList: [RecipeInfo] = []
                                for i in contents {
                                    if UserReportHelper.shared.isUserIdInUserReports(userId: Int64(i.writtenid)) {
                                        print("차단자 있음")
                                    } else {
                                        infoList.append(i)
                                    }
                                }
                                self.recipeList = infoList
                                self.dataSource.apply(self.createSnapshot(), animatingDifferences: true)
                            }
                        }
                    default:
                        return
                    }
                }
                self.delegate?.didTappedSortButton(tagNumber)
        }).disposed(by: disposeBag)
        return headerView
    }
    
    private func createSnapshot() -> Snapshot{
        var snapshot = Snapshot()
        snapshot.appendSections([.header, .recipe])
        snapshot.appendItems(mockCategoryData.map({ Item.header($0) }), toSection: .header)
        snapshot.appendItems(recipeList.map({ Item.recipe($0) }), toSection: .recipe)

        return snapshot
    }
}

extension RecipeView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        switch item {
        case .recipe(let data):
            delegate?.didTappedRecipeCell(item: data)
        default:
            return
        }
    }
}


#if DEBUG
import SwiftUI
struct ForRecipeView: UIViewRepresentable {
    typealias UIViewType = UIView
    
    func makeUIView(context: Context) -> UIView {
        RecipeView()
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
    }
}

@available(iOS 13.0, *)
struct RecipeView_Preview: PreviewProvider {
    static var previews: some View {
        ForRecipeView().ignoresSafeArea()
    }
}
#endif
