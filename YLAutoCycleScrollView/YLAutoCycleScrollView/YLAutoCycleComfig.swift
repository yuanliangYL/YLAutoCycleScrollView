//
//  YLAutoCycleComfig.swift
//  YLAutoCycleScrollView
//
//  Created by AlbertYuan on 2021/11/24.
//

import UIKit

enum YLLRollViewScrollStyle {
    case YLLRollViewScrollStyleStep  /** 渐进 可以不等宽或高*/
}

//自动滚动配置
class YLAutoCycleComfig: NSObject {

    /**
     是否循环轮播 默认YES 如果NO，则自动禁止计时器
     */
    var loopEnabled:Bool = true

    /**
     是否允许滑动 默认false
     */
    var scrollEnabled = false

    /**
     轮播方向 默认是 UICollectionViewScrollDirectionHorizontal 水平
     */
    var scrollDirection:UICollectionView.ScrollDirection = .horizontal

    /**
     轮播样式 默认是 WSLRollViewScrollStylePage 分页
     */
    var scrollStyle = YLLRollViewScrollStyle.YLLRollViewScrollStyleStep

    /**
     渐进轮播速率 单位是Point/s，以坐标系单位为准 默认60/s 如果为0 表示禁止计时器
     */
    var speed:CGFloat = 60


    /**
     item的间隔 默认值0
     */
    var spaceOfItem: CGFloat = 0

    /**
     内边距 上 左 下 右 默认值UIEdgeInsetsMake(0, 0, 0, 0)
     */
    var padding:UIEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

}
