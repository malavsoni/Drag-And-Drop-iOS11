//
//  InAppDragViewController.swift
//  iOS11DragAndDrop
//
//  Created by Malav Soni on 06/08/17.
//  Copyright © 2017 Malav Soni. All rights reserved.
//

import UIKit
import Foundation

//MARK:- UITableViewCell Class
class InAppDragTableViewCell: UITableViewCell {
    @IBOutlet weak private var imgView: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        self.imgView.layer.cornerRadius = 5.0
        self.imgView.layer.borderColor = UIColor.lightGray.cgColor
        self.imgView.layer.borderWidth = 2.0
    }
    func getImage() -> UIImage? {
        return imgView.image
    }
    func setImage(img:UIImage?) -> Void {
        self.imgView.image = img
    }
}
//MARK:- UITableViewDataSource
extension InAppDragViewController:UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return aryImageNames.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cellReference = tableView.dequeueReusableCell(withIdentifier: "reusableImageCell") as! InAppDragTableViewCell
            cellReference.setImage(img: UIImage.init(named: aryImageNames[indexPath.row]))
            return cellReference
    }
}

//MARK:- UITableViewDelegate
extension InAppDragViewController:UITableViewDelegate{
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return ((UIScreen.main.bounds.size.width / 2) * 0.5)
    }
}

//MARK:- UIDragInteractionDelegate
extension InAppDragViewController:UIDragInteractionDelegate{
    func dragInteraction(_ interaction: UIDragInteraction, itemsForBeginning session: UIDragSession) -> [UIDragItem] {
        var itemsToDrag:[UIDragItem] = []
        let buttonPosition:CGPoint = session.location(in: interaction.view)
        if let imageToDrag = self.imageExist(AtLocation: buttonPosition){
            self.dragPoint = self.containerView.convert(buttonPosition, to: self.view)
            let dragItem = UIDragItem.init(itemProvider: NSItemProvider.init(object: "\(imageToDrag.tag)" as NSString))
            dragItem.localObject = imageToDrag
            itemsToDrag.append(dragItem)
        }
        return itemsToDrag
    }
    
    func dragInteraction(_ interaction: UIDragInteraction, previewForLifting item: UIDragItem, session: UIDragSession) -> UITargetedDragPreview? {
        
        if item.localObject == nil{
            return nil
        }else{
            if let imageToDrag = self.imageExist(AtLocation: session.location(in: interaction.view)){
                return UITargetedDragPreview.init(view: imageToDrag)
            }else{
                return nil
            }
        }
    }
    
    func imageExist(AtLocation location:CGPoint) -> UIView? {
        for subView in self.containerView.subviews{
            if subView.frame.contains(location){
                return subView
            }
        }
        return nil
    }
}

//MARK:- UIDropInteractionDelegate
extension InAppDragViewController:UIDropInteractionDelegate{
    func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: NSString.self)
    }
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        let operation:UIDropOperation
        if session.localDragSession == nil{
            operation = .copy
        }else{
            operation = .move
        }
        return UIDropProposal.init(operation: operation)
    }
    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        if session.localDragSession == nil{
            // Copy Data Coming from another app.
            let dropPoint = session.location(in: interaction.view)
            for dragItem in session.items{
                    self.loadImage(item: dragItem.itemProvider, Center: dropPoint)
            }
        }else{
            // Move Data
            let dropPoint = session.location(in: interaction.view)
            if self.containerView.frame.contains(self.dragPoint) == true{
                // Dragged inside View
                if let imageToMove = self.imageExist(AtLocation: self.view.convert(self.dragPoint, to: self.containerView)) as? UIImageView{
                    imageToMove.center = dropPoint
                }
            }else{
                // Dragged From TableView
                for dragItem in session.items{
                    self.loadImage(item: dragItem.itemProvider, Center: dropPoint)
                }
            }
        }
    }
    
    func loadImage(item:NSItemProvider,Center center:CGPoint) -> Void {
        item.loadObject(ofClass: NSString.self) { (reading, error) in
            if let readingValue = reading{
                OperationQueue.main.addOperation {
                    let imageView = UIImageView.init(frame: CGRect.init(x: 0, y: 0, width: 100, height: 100))
                    imageView.image = UIImage.init(named: String(describing:readingValue))
                    imageView.contentMode = .scaleAspectFill
                    if let tagValue = Int(String(describing:readingValue)){
                        imageView.tag = tagValue
                    }
                    imageView.clipsToBounds = true
                    imageView.center = center
                    self.containerView.performSelector(onMainThread: #selector(UIImageView.addSubview(_:)), with: imageView, waitUntilDone: false)
                }
            }
        }
    }
}
//MARK:- UITableViewDragDelegate
extension InAppDragViewController:UITableViewDragDelegate{
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        var aryItemsToDrag:[UIDragItem] = []
        self.dragPoint = CGPoint.zero
        let dragItem = UIDragItem.init(itemProvider: NSItemProvider.init(object: "\(indexPath.row+1)" as NSString))
//        if let cellReference = tableView.cellForRow(at: indexPath) as? InAppDragTableViewCell{
//            dragItem.localObject = cellReference.getImage()
//        }else{
//            print("Failed to get local object")
//        }
        aryItemsToDrag.append(dragItem)
        return aryItemsToDrag
    }
}


class InAppDragViewController: UIViewController {
    @IBOutlet weak var tblReference: UITableView!
    @IBOutlet weak var containerView: UIView!
    
    var dragPoint:CGPoint = CGPoint.zero
    
    var aryImageNames:[String] = ["1","2","3","4","5","6","7","8","9","10","11"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        // Drop Interaction : To drag the Data from table view
        self.containerView.addInteraction(UIDropInteraction.init(delegate: self))
        
        // Drag Interaction : Move arount the data inside that view
        self.containerView.addInteraction(UIDragInteraction.init(delegate: self))
        
        //
        self.tblReference.dragDelegate = self
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
}
