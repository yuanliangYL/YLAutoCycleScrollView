//
//  YLAutoCycleScrollView.swift
//  YLAutoCycleScrollView
//
//  Created by AlbertYuan on 2021/11/24.
//

import UIKit

//数据源、代理
protocol YLAutoCycleScrollViewDelegate {
    /**
     返回itemSize 默认值是CGSizeMake(self.frame.size.width, self.frame.size.height);
     */
     func sizeForItemAtIndex(rollView:YLAutoCycleScrollView, index:Int) -> CGSize

    /**
     item的间隔 默认值0
     */
    func spaceOfItemInCycleView(rollView:YLAutoCycleScrollView) -> CGFloat


    /**
     内边距 上 左 下 右 默认值UIEdgeInsetsMake(0, 0, 0, 0)
     */
    func paddingOfRollView(rollView:YLAutoCycleScrollView)->UIEdgeInsets

    /**
     点击事件
     */
    func didSelectItemAtIndex(rollView:YLAutoCycleScrollView, index:Int)

    /**
     自定义item样式
     */
    func cellForItemAtIndex(rollView:YLAutoCycleScrollView, index:IndexPath) -> UICollectionViewCell
}

class YLAutoCycleScrollView: UIView {

    //默认cell标识
    final let defaultCellId = "defaultCellId"

    //配置参数
    public var comfig:YLAutoCycleComfig = YLAutoCycleComfig(){
        didSet{
            (collectionView.collectionViewLayout as! UICollectionViewFlowLayout).scrollDirection = comfig.scrollDirection
            collectionView.isScrollEnabled = comfig.scrollEnabled
        }
    }

    //指定代理
    public var delegate:YLAutoCycleScrollViewDelegate?
    //原始数据
    public var sourceArr:[Any] = []
//    {
//        didSet{
//            reloadData()
//        }
//    }

    //内部重组数据
    fileprivate var dataSource:[Any] = []

    fileprivate lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = comfig.scrollDirection

        let collect = UICollectionView(frame: CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height), collectionViewLayout: layout)
        collect.backgroundColor = .clear
        collect.delegate = self
        collect.dataSource = self
        collect.showsHorizontalScrollIndicator = false
        collect.showsVerticalScrollIndicator = false
        collect.isScrollEnabled = comfig.scrollEnabled
        //注册默认cell
        collect.register(UICollectionViewCell.self, forCellWithReuseIdentifier: defaultCellId)
        return collect
    }()

    //定时器
    fileprivate var timer :Timer?
    //弥补轮播右侧首尾相连需要增加的cell数量 比如：0 1 2 3 4 0 1 2 ，这时addRightCount = 3
    fileprivate var addRightCount:Int = 0

    //轮播右侧首尾相连的交汇点位置坐标 只有渐进效果用到
    fileprivate var connectionPoint = CGPoint.zero

    //当前源数据的索引
    fileprivate var currentPage = 0


    override init(frame: CGRect) {
        super.init(frame: frame)
        collectionView.frame = self.bounds
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        print(self.frame)
        if self.frame != CGRect.zero{
            collectionView.frame = self.bounds
            reloadData()
        }
    }
    
}

//About UI
extension YLAutoCycleScrollView{

    func setupUI(){
        addSubview(collectionView)
    }

    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        //确保清空状态
        if let _ = newSuperview, let _ = timer{
            close()
        }
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        if superview != nil{
            reloadData()
        }
    }

    //初始化内部界面数据与定时器
    func reloadData(){

        if self.frame == CGRect.zero {
            return
        }

        addRightCount = 0
        dataSource.removeAll()
        dataSource.append(contentsOf: sourceArr)

        //数据重组
        resetDataSourceForLoop()

        //界面刷新
        collectionView.reloadData()

        //开启定时器
        if sourceArr.count == 0{
            return
        }

        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(play), object: nil)
        perform(#selector(play), with: nil, afterDelay: 0.6)
    }
}


//public method
extension YLAutoCycleScrollView{
    /**
     注册item样式 用法和UICollectionView相似
     */
    public func registerClass(cellclass: AnyClass,forCellWithReuseIdentifier:String){
        collectionView.register(cellclass, forCellWithReuseIdentifier: forCellWithReuseIdentifier)
    }

    /**
     注册item样式 用法和UICollectionView相似
     */
    public func registerNib(cellNib: UINib,forCellWithReuseIdentifier:String){
        collectionView.register(cellNib, forCellWithReuseIdentifier: forCellWithReuseIdentifier)
    }

    /**
     用于初始化自定义cell，自定义cell样式 用法和UICollectionView相似
     */
    public func dequeueReusableCellWithReuseIdentifier(identifier:String, forIndexpath:IndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: forIndexpath)
    }

    /**
     返回索引为index的cell
     */
    public func cellForItemAtIndexPath(index:IndexPath) ->UICollectionViewCell?{
        return collectionView.cellForItem(at: index)
    }
}


//Data handle
extension YLAutoCycleScrollView{

    // MARK: -- 数据重点
    //数据重组 //获取首尾相连循环滚动时需要用到的元素，并重组数据源
    fileprivate func resetDataSourceForLoop(){

        if !comfig.loopEnabled {
            return
        }

        var contentSize:CGSize = CGSize.zero

        //标记屏幕内的最后一个cell
        var indexInScreen:Int = 0
        //标记初始屏幕内最后一个cell的x
        var lastOriginXY:CGFloat = 0

        ////循环原始数据：计算出contentSize
        for i in 0...sourceArr.count {
            //每一个item的标识
            let indexpath = IndexPath(item: i, section: 0)
            //横向滚动
            if comfig.scrollDirection == .horizontal {
                //计算contentSize

                //总计的宽度====左边距 + cell的宽度 + 间隔 + 右边距
                //每一个cell的宽度
                let currentCellWidth = collectionView(collectionView, layout: collectionView.collectionViewLayout, sizeForItemAt: indexpath).width

                contentSize.width = contentSize.width + (i == 0 ? comfig.padding.left : 0) + currentCellWidth + (i == sourceArr.count - 1 ? comfig.padding.right : comfig.spaceOfItem)
                contentSize.height = bounds.height

                //得到交汇处的cell
                //print(contentSize.width,self.frame.width,lastOriginX)
                //最后一个cell完全在屏幕内，或者不忘全在屏幕内但是x值在屏幕内
                if  contentSize.width <= self.frame.width
                        || (contentSize.width > self.frame.width && lastOriginXY <= self.frame.width) {
                    indexInScreen = i
                }
                lastOriginXY = i == 0 ? comfig.padding.left : contentSize.width
            }

            else{
                //纵向滚动
                //高度计算
                //总计的宽度====左边距 + cell的宽度 + 间隔 + 右边距
                let currentCellHeight = collectionView(collectionView, layout: collectionView.collectionViewLayout, sizeForItemAt: indexpath).height

                contentSize.height = contentSize.height + (i == 0 ? comfig.padding.top : 0) + currentCellHeight + (i == sourceArr.count - 1 ? comfig.padding.right : comfig.spaceOfItem)
                contentSize.width = bounds.width

                //得到交汇处的cell
                //print(contentSize.width,self.frame.width,lastOriginX)
                //最后一个cell完全在屏幕内，或者不忘全在屏幕内但是x值在屏幕内
                if  contentSize.height <= self.frame.height
                        || (contentSize.height > self.frame.height && lastOriginXY <= self.frame.height) {
                    indexInScreen = i
                }
                lastOriginXY = i == 0 ? comfig.padding.top : contentSize.height
            }

        }
        /*
         循环滚动：思想当然还是3 >4 >0 >1 >2 >3 >4 >0 >1，关键就在于怎么确定弥补两端轮播首尾相连需要增加的cell，
         前边尾首相连需要UICollectionView可见范围内的数据源后边的元素cell，
         后边首尾相连需要UICollectionView可见范围内的数据源前边的元素cell
         */

        //横向滚动且contentSize大于frame的：及存在滚动需求
        if comfig.scrollDirection == .horizontal && contentSize.width >= self.frame.size.width {
            //用于右侧连接元素数量：弥补轮播右侧首尾相连需要增加的cell数量
//            let point = CGPoint(x: self.frame.size.width - 1, y: 0)

            //获取交汇处的index的row值
            addRightCount = indexInScreen + 1
//            addRightCount = (collectionView.indexPathForItem(at: point)?.row ?? 0) + 1

//            print(collectionView.indexPathForItem(at: point)?.row as Any,addRightCount,self.frame.width,contentSize.width)
        }

        else if comfig.scrollDirection == .vertical && contentSize.height >= self.frame.size.height {

            addRightCount = indexInScreen + 1

//            let point = CGPoint(x: 0, y: self.frame.size.height - 1)
//            addRightCount = (collectionView.indexPathForItem(at: point)?.row ?? 0) + 1

        }


        if sourceArr.count != 0{
            let appendArr = sourceArr[0..<addRightCount]
            //追加数据
            dataSource.append(contentsOf:appendArr)
        }
    }

    //根据处理后的数据源的索引row 返回原数据的索引index
    fileprivate func indexOfSourceArray(inRow:Int)->Int{
        var index = 0

        if sourceArr.count == 0{
            return index
        }

        if inRow < sourceArr.count{
            index = inRow
        }else{
            index = inRow % sourceArr.count
        }
        return index
    }
}

//collectionview
extension YLAutoCycleScrollView:UICollectionViewDelegate ,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout{

    // MARK: -- UICollectionViewDataSource
    //组个数
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    //组内成员个数
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }
    // 返回每个cell
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        //等到原始数据对应的index
        let realIndex = IndexPath(row: indexOfSourceArray(inRow: indexPath.row), section: indexPath.section)

        guard let cell = delegate?.cellForItemAtIndex(rollView: self, index: realIndex) else{
            //default cell
            let defaultCell = collectionView .dequeueReusableCell(withReuseIdentifier: "defaultCellId", for: indexPath)
            return defaultCell
        }
        return cell
    }


    // MARK: -- UICollectionViewDelegate
    //点击事件
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        let realIndex = IndexPath(row: indexOfSourceArray(inRow: indexPath.row), section: indexPath.section)

        delegate?.didSelectItemAtIndex(rollView: self, index: realIndex.row)
    }


    // MARK: -- UICollectionViewDelegateFlowLayout
    /**
     item的大小
     */
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

        let realIndex = IndexPath(row: indexOfSourceArray(inRow: indexPath.row), section: indexPath.section)

        guard let size = delegate?.sizeForItemAtIndex(rollView: self, index: realIndex.row) else{
            //default
            return CGSize(width: self.frame.width, height: self.frame.height)
        }

        return size
    }

    /**
     行间距
     */
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {

        guard let space = delegate?.spaceOfItemInCycleView(rollView: self) else {
            return comfig.spaceOfItem
        }
        comfig.spaceOfItem = space
        return space
    }


    /**
     列间距
     */
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        guard let space = delegate?.spaceOfItemInCycleView(rollView: self) else {
            return comfig.spaceOfItem
        }
        comfig.spaceOfItem = space
        return space
    }

    /**
     组间距
     */
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        guard let padding = delegate?.paddingOfRollView(rollView: self) else {
            return comfig.padding

        }
        comfig.padding = padding
        return padding
    }
}




//timer
extension YLAutoCycleScrollView{

    //定时器销毁，界面元素移除：内存处理
    fileprivate func close(){
        invalidateTimer()

        subviews.forEach { subs in
            subs.removeFromSuperview()
        }
    }

    fileprivate func pause(){
        invalidateTimer()
    }

    @objc fileprivate func play(){
        invalidateTimer()

        //如果速率或者时间间隔为0，表示不启用计时器
        if comfig.speed == 0 || !comfig.loopEnabled {
            collectionView.isScrollEnabled = comfig.scrollEnabled
            return
        }

        //开启定时器
        timer = Timer.scheduledTimer(timeInterval: 1.0/60, target: self, selector: #selector(timerEvent), userInfo: timerEvent, repeats: true)
        RunLoop.current.add(timer!, forMode: .common)
    }


    fileprivate func invalidateTimer(){

        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(play), object: nil)
        if timer != nil{
            timer?.invalidate()
            timer = nil
        }
    }

    //定时器处理逻辑
    @objc fileprivate func timerEvent(){

        if comfig.scrollDirection == .horizontal{

            //如果不够一屏就停止滚动效果
            if collectionView.contentSize.width < self.frame.size.width {
                pause()
                return
            }

            //水平动画
            horizontalRollAnimation()
        }

        else{

            if collectionView.contentSize.height < self.frame.size.height {
                pause()
                return
            }
            //垂直动画
            verticalRollAnimation()
        }
    }
}


//animation
extension YLAutoCycleScrollView{

    /**
     水平方向跑马灯 渐进动画
     */
    fileprivate func horizontalRollAnimation(){

        //没有内容不需要滚动
        if collectionView.contentSize.width == 0{
            return
        }

        //位置调整
        resetContentOffset()

        //无动画效果滚动：渐进
        let point = CGPoint(x: collectionView.contentOffset.x + comfig.speed * 1.0/60, y: comfig.padding.top)
        collectionView.setContentOffset(point, animated: false)
    }


    /**
     垂直方向跑马灯 渐进动画
     */
    fileprivate func verticalRollAnimation(){
        if collectionView.contentSize.height == 0{
            return
        }

        //位置调整
        resetContentOffset()

        //无动画效果滚动：渐进
        let point = CGPoint(x: comfig.padding.left, y: collectionView.contentOffset.y + comfig.speed * 1.0/60)
        collectionView.setContentOffset(point, animated: false)
    }


    // MARK: -- 动画重点
    /**
     滑动到首尾连接处时需要复原至对应的位置 :重点
     */
    fileprivate func resetContentOffset(){

        //只有当IndexPath位置上的cell可见时，才能用如下方法获取到对应的cell，否则为nil
        //等到交汇处的indexpath
        let indexi = IndexPath(row: dataSource.count - addRightCount, section: 0)

        //得到交汇处的cell
        if let cell = collectionView .cellForItem(at: indexi){
            //获取渐进轮播首尾相连的交汇点位置坐标
            //定时器下实时计算cell在collectionView的origin位置
            connectionPoint = collectionView.convert(cell.frame, to: collectionView).origin
            //print(indexi ,cell,connectionPoint.x,dataSource.count,addRightCount)

        }else{
            connectionPoint = CGPoint.zero
        }


        if comfig.scrollDirection == .horizontal {
            //水平

            if collectionView.contentOffset.x >= connectionPoint.x && connectionPoint.x != 0{
                //交汇处处理:通过setContentOffset移动到最初的位置，造成循环的假象
                let point = CGPoint(x: comfig.padding.left, y: comfig.padding.top)
                collectionView.setContentOffset(point, animated: false)
            }
        }

        else{
            //垂直
            if collectionView.contentOffset.y >= connectionPoint.y && connectionPoint.y != 0{
                //交汇处处理
                let point = CGPoint(x: comfig.padding.left, y: comfig.padding.top)
                collectionView.setContentOffset(point, animated: false)
            }
        }
    }
}



//scrollView
extension YLAutoCycleScrollView:UIScrollViewDelegate {

    /*************************************缓慢拖动、快速拖动都会调用************************************/
    // scrollView 开始拖动(刚有拖动的迹象就调用,即在调用scrollViewDidScroll之前就会调用scrollViewWillBeginDragging方法)
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {

        if (timer != nil) {
            pause()
        }

    }

    // scrollView 结束拖动(松开鼠标停止拖动的那一瞬间调用)
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if decelerate == false && comfig.loopEnabled{
            resetContentOffset()
        }
    }

    // scrollView 已经滑动(拖动就调用，只要你不停的拖动，这个方法就会调用无数次)
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if comfig.loopEnabled{
            resetContentOffset()
            play()
        }
    }
    /************************************快速拖动才会调用*********************************************/
    // scrollView 即将开始减速
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
    }
    // scrollView 结束减速(必须得有快速拖动的动作，立马停止拖动就会调用。如果是缓慢拖动，停止拖动时不会调用这个方法)
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {

    }
    //// 当通过动画设置偏移量或者滚动到指定可视区域时调用called when setContentOffset/scrollRectVisible:animated: finishes. not called if not animating
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        if comfig.loopEnabled{
            resetContentOffset()
        }
    }
}




