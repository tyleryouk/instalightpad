//
//  commentVC.swift
//  Instragram
//
//  Created by Ahmad Idigov on 20.12.15.
//  Copyright © 2015 Akhmed Idigov. All rights reserved.
//

import UIKit
import Parse


var commentuuid = [String]()
var commentowner = [String]()

class commentVC: UIViewController, UITextViewDelegate, UITableViewDelegate, UITableViewDataSource {
    
    // UI objects
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var commentTxt: UITextView!
    @IBOutlet weak var sendBtn: UIButton!
    var refresher = UIRefreshControl()
    
    // values for reseting UI to default
    var tableViewHeight : CGFloat = 0
    var commentY : CGFloat = 0
    var commentHeight : CGFloat = 0
    
    // arrays to hold server data
    var usernameArray = [String]()
    var avaArray = [PFFile]()
    var commentArray = [String]()
    var dateArray = [NSDate?]()
    
    // variable to hold keybarod frame
    var keyboard = CGRect()
    
    // page size
    var page : Int32 = 15
    

    // default func
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // title at the top
        self.navigationItem.title = "COMMENTS"
        
        // new back button
        self.navigationItem.hidesBackButton = true
        let backBtn = UIBarButtonItem(image: UIImage(named: "back.png"), style: .Plain, target: self, action: #selector(commentVC.back(_:)))
        self.navigationItem.leftBarButtonItem = backBtn
        
        // swipe to go back
        let backSwipe = UISwipeGestureRecognizer(target: self, action: #selector(commentVC.back(_:)))
        backSwipe.direction = UISwipeGestureRecognizerDirection.Right
        self.view.addGestureRecognizer(backSwipe)
        
        // catch notification if the keyboard is shown or hidden
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(commentVC.keyboardWillShow(_:)), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(commentVC.keyboardWillHide(_:)), name: UIKeyboardWillHideNotification, object: nil)
        
        // disable button from the beginning
        sendBtn.enabled = false
        
        // call functions
        alignment()
        loadComments()
    }
    
    
    // preload func
    override func viewWillAppear(animated: Bool) {

        // hide bottom bar
        self.tabBarController?.tabBar.hidden = true
        
        // hide custom tabbar button
        tabBarPostButton.hidden = true
        
        // call keyboard
        commentTxt.becomeFirstResponder()
    }
    
    
    // postload func - launches when we about to live current VC
    override func viewWillDisappear(animated: Bool) {
        
        // unhide tabbar
        self.tabBarController?.tabBar.hidden = false
        
        // unhide custom tabbar button
        tabBarPostButton.hidden = false
    }
    
    
    // func loading when keyboard is shown
    func keyboardWillShow(notification : NSNotification) {
        
        // defnine keyboard frame size
        keyboard = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey]!.CGRectValue)!
        
        // move UI up
        UIView.animateWithDuration(0.4) { () -> Void in
            self.tableView.frame.size.height = self.tableViewHeight - self.keyboard.height - self.commentTxt.frame.size.height + self.commentHeight
            self.commentTxt.frame.origin.y = self.commentY - self.keyboard.height - self.commentTxt.frame.size.height + self.commentHeight
            self.sendBtn.frame.origin.y = self.commentTxt.frame.origin.y
        }
    }
    
    
    // func loading when keyboard is hidden
    func keyboardWillHide(notification : NSNotification) {
        
        // move UI down
        UIView.animateWithDuration(0.4) { () -> Void in
            self.tableView.frame.size.height = self.tableViewHeight
            self.commentTxt.frame.origin.y = self.commentY
            self.sendBtn.frame.origin.y = self.commentY
        }
    }
    
    
    // alignment function
    func alignment() {
        
        // alignnment
        let width = self.view.frame.size.width
        let height = self.view.frame.size.height
        
        tableView.frame = CGRectMake(0, 0, width, height / 1.096 - self.navigationController!.navigationBar.frame.size.height - 20)
        tableView.estimatedRowHeight = width / 5.333
        tableView.rowHeight = UITableViewAutomaticDimension
        
        commentTxt.frame = CGRectMake(10, tableView.frame.size.height + height / 56.8, width / 1.306, 33)
        commentTxt.layer.cornerRadius = commentTxt.frame.size.width / 50
        
        sendBtn.frame = CGRectMake(commentTxt.frame.origin.x + commentTxt.frame.size.width + width / 32, commentTxt.frame.origin.y, width - (commentTxt.frame.origin.x + commentTxt.frame.size.width) - (width / 32) * 2, commentTxt.frame.size.height)
        
        
        // delegates
        commentTxt.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        
        // assign reseting values
        tableViewHeight = tableView.frame.size.height
        commentHeight = commentTxt.frame.size.height
        commentY = commentTxt.frame.origin.y
    }
    
    
    // while writing something
    func textViewDidChange(textView: UITextView) {
        
        // disable button if entered no text
        let spacing = NSCharacterSet.whitespaceAndNewlineCharacterSet()
        if !commentTxt.text.stringByTrimmingCharactersInSet(spacing).isEmpty {
            sendBtn.enabled = true
        } else {
            sendBtn.enabled = false
        }
        
        // + paragraph
        if textView.contentSize.height > textView.frame.size.height && textView.frame.height < 130 {
            
            // find difference to add
            let difference = textView.contentSize.height - textView.frame.size.height
            
            // redefine frame of commentTxt
            textView.frame.origin.y = textView.frame.origin.y - difference
            textView.frame.size.height = textView.contentSize.height
            
            // move up tableView
            if textView.contentSize.height + keyboard.height + commentY >= tableView.frame.size.height {
                tableView.frame.size.height = tableView.frame.size.height - difference
            }
        }
        
        // - paragraph
        else if textView.contentSize.height < textView.frame.size.height {
            
            // find difference to deduct
            let difference = textView.frame.size.height - textView.contentSize.height
            
            // redefine frame of commentTxt
            textView.frame.origin.y = textView.frame.origin.y + difference
            textView.frame.size.height = textView.contentSize.height
            
            // move donw tableViwe
            if textView.contentSize.height + keyboard.height + commentY > tableView.frame.size.height {
                tableView.frame.size.height = tableView.frame.size.height + difference
            }
        }
    }
    
    
    // load comments function
    func loadComments() {
        
        // STEP 1. Count total comments in order to skip all except (page size = 15)
        let countQuery = PFQuery(className: "comments")
        countQuery.whereKey("to", equalTo: commentuuid.last!)
        countQuery.countObjectsInBackgroundWithBlock ({ (count:Int32, error:NSError?) -> Void in
            
            // if comments on the server for current post are more than (page size 15), implement pull to refresh func
            if self.page < count {
                self.refresher.addTarget(self, action: #selector(commentVC.loadMore), forControlEvents: UIControlEvents.ValueChanged)
                self.tableView.addSubview(self.refresher)
            }
            
            // STEP 2. Request last (page size 15) comments
            let query = PFQuery(className: "comments")
            query.whereKey("to", equalTo: commentuuid.last!)
            query.skip = count - self.page
            query.addAscendingOrder("createdAt")
            query.findObjectsInBackgroundWithBlock({ (objects:[PFObject]?, erro:NSError?) -> Void in
                if error == nil {
                    
                    // clean up
                    self.usernameArray.removeAll(keepCapacity: false)
                    self.avaArray.removeAll(keepCapacity: false)
                    self.commentArray.removeAll(keepCapacity: false)
                    self.dateArray.removeAll(keepCapacity: false)
                    
                    // find related objects
                    for object in objects! {
                        self.usernameArray.append(object.objectForKey("username") as! String)
                        self.avaArray.append(object.objectForKey("ava") as! PFFile)
                        self.commentArray.append(object.objectForKey("comment") as! String)
                        self.dateArray.append(object.createdAt)
                        self.tableView.reloadData()
                        
                        // scroll to bottom
                        self.tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: self.commentArray.count - 1, inSection: 0), atScrollPosition: UITableViewScrollPosition.Bottom, animated: false)
                    }
                } else {
                    print(error?.localizedDescription)
                }
            })
        })
        
    }
    
    
    // pagination
    func loadMore() {
        
        // STEP 1. Count total comments in order to skip all except (page size = 15)
        let countQuery = PFQuery(className: "comments")
        countQuery.whereKey("to", equalTo: commentuuid.last!)
        countQuery.countObjectsInBackgroundWithBlock ({ (count:Int32, error:NSError?) -> Void in
            
            // self refresher
            self.refresher.endRefreshing()
            
            // remove refresher if loaded all comments
            if self.page >= count {
                self.refresher.removeFromSuperview()
            }
            
            // STEP 2. Load more comments
            if self.page < count {
                
                // increase page to load 30 as first paging
                self.page = self.page + 15
                
                // request existing comments from the server
                let query = PFQuery(className: "comments")
                query.whereKey("to", equalTo: commentuuid.last!)
                query.skip = count - self.page
                query.addAscendingOrder("createdAt")
                query.findObjectsInBackgroundWithBlock({ (objects:[PFObject]?, error:NSError?) -> Void in
                    if error == nil {
                        
                        // clean up
                        self.usernameArray.removeAll(keepCapacity: false)
                        self.avaArray.removeAll(keepCapacity: false)
                        self.commentArray.removeAll(keepCapacity: false)
                        self.dateArray.removeAll(keepCapacity: false)
                        
                        // find related objects
                        for object in objects! {
                            self.usernameArray.append(object.objectForKey("username") as! String)
                            self.avaArray.append(object.objectForKey("ava") as! PFFile)
                            self.commentArray.append(object.objectForKey("comment") as! String)
                            self.dateArray.append(object.createdAt)
                            self.tableView.reloadData()
                        }
                    } else {
                        print(error?.localizedDescription)
                    }
                })
            }
            
        })
        
    }
    
    
    // clicked send button
    @IBAction func sendBtn_click(sender: AnyObject) {
        
        // STEP 1. Add row in tableView
        usernameArray.append(PFUser.currentUser()!.username!)
        avaArray.append(PFUser.currentUser()?.objectForKey("ava") as! PFFile)
        dateArray.append(NSDate())
        commentArray.append(commentTxt.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()))
        tableView.reloadData()
        
        // STEP 2. Send comment to server
        let commentObj = PFObject(className: "comments")
        commentObj["to"] = commentuuid.last
        commentObj["username"] = PFUser.currentUser()?.username
        commentObj["ava"] = PFUser.currentUser()?.valueForKey("ava")
        commentObj["comment"] = commentTxt.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        commentObj.saveEventually()
        
        // STEP 3. Send #hashtag to server
        let words:[String] = commentTxt.text!.componentsSeparatedByCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        
        // define taged word
        for var word in words {
            
            // save #hasthag in server
            if word.hasPrefix("#") {
                
                // cut symbold
                word = word.stringByTrimmingCharactersInSet(NSCharacterSet.punctuationCharacterSet())
                word = word.stringByTrimmingCharactersInSet(NSCharacterSet.symbolCharacterSet())
                
                let hashtagObj = PFObject(className: "hashtags")
                hashtagObj["to"] = commentuuid.last
                hashtagObj["by"] = PFUser.currentUser()?.username
                hashtagObj["hashtag"] = word.lowercaseString
                hashtagObj["comment"] = commentTxt.text
                hashtagObj.saveInBackgroundWithBlock({ (success:Bool, error:NSError?) -> Void in
                    if success {
                        print("hashtag \(word) is created")
                    } else {
                        print(error!.localizedDescription)
                    }
                })
            }
        }
        
        
        // STEP 4. Send notification as @mention
        var mentionCreated = Bool()
        
        for var word in words {
            
            // check @mentions for user
            if word.hasPrefix("@") {
                
                // cut symbols
                word = word.stringByTrimmingCharactersInSet(NSCharacterSet.punctuationCharacterSet())
                word = word.stringByTrimmingCharactersInSet(NSCharacterSet.symbolCharacterSet())
                
                let newsObj = PFObject(className: "news")
                newsObj["by"] = PFUser.currentUser()?.username
                newsObj["ava"] = PFUser.currentUser()?.objectForKey("ava") as! PFFile
                newsObj["to"] = word
                newsObj["owner"] = commentowner.last
                newsObj["uuid"] = commentuuid.last
                newsObj["type"] = "mention"
                newsObj["checked"] = "no"
                newsObj.saveEventually()
                mentionCreated = true
            }
        }
        
        // STEP 5. Send notification as comment
        if commentowner.last != PFUser.currentUser()?.username && mentionCreated == false {
            let newsObj = PFObject(className: "news")
            newsObj["by"] = PFUser.currentUser()?.username
            newsObj["ava"] = PFUser.currentUser()?.objectForKey("ava") as! PFFile
            newsObj["to"] = commentowner.last
            newsObj["owner"] = commentowner.last
            newsObj["uuid"] = commentuuid.last
            newsObj["type"] = "comment"
            newsObj["checked"] = "no"
            newsObj.saveEventually()
        }
        
        
        // scroll to bottom
        self.tableView.scrollToRowAtIndexPath(NSIndexPath(forItem: commentArray.count - 1, inSection: 0), atScrollPosition: UITableViewScrollPosition.Bottom, animated: false)
        
        // STAEP 6. Reset UI
        sendBtn.enabled = false
        commentTxt.text = ""
        commentTxt.frame.size.height = commentHeight
        commentTxt.frame.origin.y = sendBtn.frame.origin.y
        tableView.frame.size.height = self.tableViewHeight - self.keyboard.height - self.commentTxt.frame.size.height + self.commentHeight
    }
    
    
    // TABLEVIEW
    // cell numb
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return commentArray.count
    }
    
    // cell height
    func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    // cell config
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        // declare cell
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell") as! commentCell
        
        cell.usernameBtn.setTitle(usernameArray[indexPath.row], forState: .Normal)
        cell.usernameBtn.sizeToFit()
        cell.commentLbl.text = commentArray[indexPath.row]
        avaArray[indexPath.row].getDataInBackgroundWithBlock { (data:NSData?, error:NSError?) -> Void in
            cell.avaImg.image = UIImage(data: data!)
        }
        
        // calculate date
        let from = dateArray[indexPath.row]
        let now = NSDate()
        let components : NSCalendarUnit = [.Second, .Minute, .Hour, .Day, .WeekOfMonth]
        let difference = NSCalendar.currentCalendar().components(components, fromDate: from!, toDate: now, options: [])
        
        if difference.second <= 0 {
            cell.dateLbl.text = "now"
        }
        if difference.second > 0 && difference.minute == 0 {
            cell.dateLbl.text = "\(difference.second)s."
        }
        if difference.minute > 0 && difference.hour == 0 {
            cell.dateLbl.text = "\(difference.minute)m."
        }
        if difference.hour > 0 && difference.day == 0 {
            cell.dateLbl.text = "\(difference.hour)h."
        }
        if difference.day > 0 && difference.weekOfMonth == 0 {
            cell.dateLbl.text = "\(difference.day)d."
        }
        if difference.weekOfMonth > 0 {
            cell.dateLbl.text = "\(difference.weekOfMonth)w."
        }
        
        
        // @mention is tapped
        cell.commentLbl.userHandleLinkTapHandler = { label, handle, rang in
            var mention = handle
            mention = String(mention.characters.dropFirst())
            
            // if tapped on @currentUser go home, else go guest
            if mention.lowercaseString == PFUser.currentUser()?.username {
                let home = self.storyboard?.instantiateViewControllerWithIdentifier("homeVC") as! homeVC
                self.navigationController?.pushViewController(home, animated: true)
            } else {
                guestname.append(mention.lowercaseString)
                let guest = self.storyboard?.instantiateViewControllerWithIdentifier("guestVC") as! guestVC
                self.navigationController?.pushViewController(guest, animated: true)
            }
        }
        
        // #hashtag is tapped
        cell.commentLbl.hashtagLinkTapHandler = { label, handle, range in
            var mention = handle
            mention = String(mention.characters.dropFirst())
            hashtag.append(mention.lowercaseString)
            let hashvc = self.storyboard?.instantiateViewControllerWithIdentifier("hashtagsVC") as! hashtagsVC
            self.navigationController?.pushViewController(hashvc, animated: true)
        }
        
        
        // assign indexes of buttons
        cell.usernameBtn.layer.setValue(indexPath, forKey: "index")
        
        return cell
    }
    
    
    // clicked username button
    @IBAction func usernameBtn_click(sender: AnyObject) {
        
        // call index of current button
        let i = sender.layer.valueForKey("index") as! NSIndexPath
        
        // call cell to call further cell data
        let cell = tableView.cellForRowAtIndexPath(i) as! commentCell
        
        // if user tapped on his username go home, else go guest
        if cell.usernameBtn.titleLabel?.text == PFUser.currentUser()?.username {
            let home = self.storyboard?.instantiateViewControllerWithIdentifier("homeVC") as! homeVC
            self.navigationController?.pushViewController(home, animated: true)
        } else {
            guestname.append(cell.usernameBtn.titleLabel!.text!)
            let guest = self.storyboard?.instantiateViewControllerWithIdentifier("guestVC") as! guestVC
            self.navigationController?.pushViewController(guest, animated: true)
        }
    }
    
    
    // cell editabily
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    
    // swipe cell for actions
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        
        // call cell for calling further cell data
        let cell = tableView.cellForRowAtIndexPath(indexPath) as! commentCell
        
        // ACTION 1. Delete
        let delete = UITableViewRowAction(style: .Normal, title: "    ") { (action:UITableViewRowAction, indexPath:NSIndexPath) -> Void in
            
            // STEP 1. Delete comment from server
            let commentQuery = PFQuery(className: "comments")
            commentQuery.whereKey("to", equalTo: commentuuid.last!)
            commentQuery.whereKey("comment", equalTo: cell.commentLbl.text!)
            commentQuery.findObjectsInBackgroundWithBlock ({ (objects:[PFObject]?, error:NSError?) -> Void in
                if error == nil {
                    // find related objects
                    for object in objects! {
                        object.deleteEventually()
                    }
                } else {
                    print(error!.localizedDescription)
                }
            })
            
            // STEP 2. Delete #hashtag from server
            let hashtagQuery = PFQuery(className: "hashtags")
            hashtagQuery.whereKey("to", equalTo: commentuuid.last!)
            hashtagQuery.whereKey("by", equalTo: cell.usernameBtn.titleLabel!.text!)
            hashtagQuery.whereKey("comment", equalTo: cell.commentLbl.text!)
            hashtagQuery.findObjectsInBackgroundWithBlock({ (objects:[PFObject]?, error:NSError?) -> Void in
                for object in objects! {
                    object.deleteEventually()
                }
            })
            
            // STEP 3. Delete notification: mention comment
            let newsQuery = PFQuery(className: "news")
            newsQuery.whereKey("by", equalTo: cell.usernameBtn.titleLabel!.text!)
            newsQuery.whereKey("to", equalTo: commentowner.last!)
            newsQuery.whereKey("uuid", equalTo: commentuuid.last!)
            newsQuery.whereKey("type", containedIn: ["comment", "mention"])
            newsQuery.findObjectsInBackgroundWithBlock({ (objects:[PFObject]?, error:NSError?) -> Void in
                if error == nil {
                    for object in objects! {
                        object.deleteEventually()
                    }
                }
            })
            
            
            // close cell
            tableView.setEditing(false, animated: true)
            
            // STEP 3. Delete comment row from tableView
            self.commentArray.removeAtIndex(indexPath.row)
            self.dateArray.removeAtIndex(indexPath.row)
            self.usernameArray.removeAtIndex(indexPath.row)
            self.avaArray.removeAtIndex(indexPath.row)
            
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        }
        
        // ACTION 2. Mention or address message to someone
        let address = UITableViewRowAction(style: .Normal, title: "    ") { (action:UITableViewRowAction, indexPath:NSIndexPath) -> Void in
            
            // include username in textView
            self.commentTxt.text = "\(self.commentTxt.text + "@" + self.usernameArray[indexPath.row] + " ")"
            
            // enable button
            self.sendBtn.enabled = true
            
            // close cell
            tableView.setEditing(false, animated: true)
        }
        
        // ACTION 3. Complain
        let complain = UITableViewRowAction(style: .Normal, title: "    ") { (action:UITableViewRowAction, indexPath:NSIndexPath) -> Void in
            
            // send complain to server regarding selected comment
            let complainObj = PFObject(className: "complain")
            complainObj["by"] = PFUser.currentUser()?.username
            complainObj["to"] = cell.commentLbl.text
            complainObj["owner"] = cell.usernameBtn.titleLabel?.text
            complainObj.saveInBackgroundWithBlock({ (success:Bool, error:NSError?) -> Void in
                if success {
                    self.alert("Complain has been made successfully", message: "Thank You! We will consider your complain")
                } else {
                    self.alert("ERROR", message: error!.localizedDescription)
                }
            })
            
            // close cell
            tableView.setEditing(false, animated: true)
        }
        
        // buttons background
        delete.backgroundColor = UIColor(patternImage: UIImage(named: "delete.png")!)
        address.backgroundColor = UIColor(patternImage: UIImage(named: "address.png")!)
        complain.backgroundColor = UIColor(patternImage: UIImage(named: "complain.png")!)
        
        // comment beloogs to user
        if cell.usernameBtn.titleLabel?.text == PFUser.currentUser()?.username {
            return [delete, address]
        }
        
        // post belongs to user
        else if commentowner.last == PFUser.currentUser()?.username {
            return [delete, address, complain]
        }
        
        // post belongs to another user
        else  {
            return [address, complain]
        }
        
    }
    
    
    // alert action
    func alert (title: String, message : String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        let ok = UIAlertAction(title: "OK", style: .Cancel, handler: nil)
        alert.addAction(ok)
        presentViewController(alert, animated: true, completion: nil)
    }
    
    
    // go back
    func back(sender : UIBarButtonItem) {
        
        // push back
        self.navigationController?.popViewControllerAnimated(true)
        
        // clean comment uui from last holding infromation
        if !commentuuid.isEmpty {
            commentuuid.removeLast()
        }
        
        // clean comment owner from last holding infromation
        if !commentowner.isEmpty {
            commentowner.removeLast()
        }
    }

}