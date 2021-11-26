//
//  ViewController.swift
//  YLAutoCycleScrollView
//
//  Created by AlbertYuan on 2021/11/24.
//

import UIKit



class ViewController: UIViewController {

    var autoCycleView:YLAutoCycleScrollView!

    let dataArr = ["1","2","3","4","5","6","7","8","9"]

    override func viewDidLoad() {
        super.viewDidLoad()

        autoCycleView = YLAutoCycleScrollView(frame: CGRect(x: 0, y: 200, width: view.frame.width, height: 100))
        autoCycleView.sourceArr = dataArr
        autoCycleView.backgroundColor = .yellow
        autoCycleView.delegate = self
        autoCycleView.registerClass(cellclass: UICollectionViewCell.self, forCellWithReuseIdentifier: "mycell")
        autoCycleView.registerNib(cellNib: UINib.init(nibName: "YLTopGoodInfoCell", bundle: nil), forCellWithReuseIdentifier: "YLTopGoodInfoCell")
        view.addSubview(autoCycleView)

       
    }


}

extension ViewController:YLAutoCycleScrollViewDelegate{
    func sizeForItemAtIndex(rollView: YLAutoCycleScrollView, index: Int) -> CGSize {
        return CGSize(width: 120, height: 80)
    }

    func spaceOfItemInCycleView(rollView: YLAutoCycleScrollView) -> CGFloat {
        return 10
    }

    func paddingOfRollView(rollView: YLAutoCycleScrollView) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
    }

    func didSelectItemAtIndex(rollView: YLAutoCycleScrollView, index: Int) {
        print("did selected cell in \(index)")
    }

    func cellForItemAtIndex(rollView: YLAutoCycleScrollView, index: IndexPath) -> UICollectionViewCell {
//        let cell = rollView.dequeueReusableCellWithReuseIdentifier(identifier: "mycell", forIndexpath: index)


        let cell:YLTopGoodInfoCell = rollView.dequeueReusableCellWithReuseIdentifier(identifier: "YLTopGoodInfoCell", forIndexpath: index) as! YLTopGoodInfoCell
        cell.textStr = dataArr[index.row]
        cell.backgroundColor = UIColor.clear

        return cell
    }
}

