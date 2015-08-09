//
//  ThreadViewController.swift
//  Aozora
//
//  Created by Paul Chavarria Podoliako on 8/7/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import UIKit
import ANCommonKit
import TTTAttributedLabel
import XCDYouTubeKit
import Parse

// Class intended to be subclassedb
public class ThreadViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var dismissBBI: UIBarButtonItem!
    @IBOutlet weak var createBBI: UIBarButtonItem!
    
    var thread: Thread? {
        didSet {
            if isViewLoaded() {
                updateUIWithThread(thread!)
            }
        }
    }
    var postType: CommentViewController.PostType!
    
    var fetchController = FetchController()
    var refreshControl = UIRefreshControl()
    var loadingView: LoaderView!
    var playerController: XCDYouTubeVideoPlayerViewController?
    
    public func initWithThread(thread: Thread, postType: CommentViewController.PostType) {
        self.thread = thread
        self.postType = postType
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.alpha = 0.0
        tableView.estimatedRowHeight = 112.0
        tableView.rowHeight = UITableViewAutomaticDimension
        
        CommentCell.registerNibFor(tableView: tableView)
        WriteACommentCell.registerNibFor(tableView: tableView)
        
        loadingView = LoaderView(parentView: view)
        addRefreshControl(refreshControl, action:"updateThread", forTableView: tableView)
        
        if let thread = thread {
            updateUIWithThread(thread)
        } else {
            fetchThread()
        }
    }
    
    func updateUIWithThread(thread: Thread) {
        updateThread()
    }
    
    // MARK: - Fetching
    func fetchThread() {
        
    }
    
    func updateThread() {

    }
    
    // MARK: - Internal functions
    func openProfile(user: User) {
        if user != User.currentUser() {
            let navController = UIStoryboard(name: "Profile", bundle: nil).instantiateInitialViewController() as! UINavigationController
            let profileController = navController.viewControllers.first as! ProfileViewController
            profileController.initWithUser(user)
            presentViewController(navController, animated: true, completion: nil)
        }
    }
    
    func showImage(imageURLString: String, imageView: UIImageView) {
        if let imageURL = NSURL(string: imageURLString) {
            presentImageViewController(imageView, imageUrl: imageURL)
        }
    }
    
    func playTrailer(videoID: String) {
        playerController = XCDYouTubeVideoPlayerViewController(videoIdentifier: videoID)
        presentMoviePlayerViewControllerAnimated(playerController)
    }
    
    func replyTo(post: Postable) {
        let comment = ANParseKit.commentViewController()
        if let post = post as? ThreadPostable, let thread = thread {
            comment.initWithThread(thread, postType: postType, delegate: self, parentPost: post)
        } else {
            comment.initWithTimelinePost(self, parentPost: post)
        }
        presentViewController(comment, animated: true, completion: nil)
        
    }
    
    func postForCell(cell: UITableViewCell) -> Postable? {
        if let indexPath = tableView.indexPathForCell(cell), let post = fetchController.objectAtIndex(indexPath.section) as? Postable {
            if indexPath.row == 0 {
                return post
            } else if let replies = post.replies where indexPath.row <= replies.count {
                return replies[indexPath.row - 1] as? Postable
            }
        }
        
        return nil
    }
    
    // MARK: - IBAction
    
    @IBAction public func dismissPressed(sender: AnyObject) {
        navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction public func replyToThreadPressed(sender: AnyObject) {
        
    }
}


extension ThreadViewController: UITableViewDataSource {
    
    public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return fetchController.dataCount()
    }
    
    public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let post = fetchController.objectAtIndex(section) as! Postable
        if post.replies?.count > 0 {
            return 1 + (post.replies?.count ?? 0) + 1
        } else {
            return 1
        }
    }
    
    public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let post = fetchController.objectAtIndex(indexPath.section) as! Postable
        
        if indexPath.row == 0 {
            
            var reuseIdentifier = ""
            if post.images != nil || post.youtubeID != nil || post.episode != nil {
                // Post image or video cell
                reuseIdentifier = "PostImageCell"
            } else {
                // Text post update
                reuseIdentifier = "PostTextCell"
            }
            
            let cell = tableView.dequeueReusableCellWithIdentifier(reuseIdentifier) as! PostCell
            cell.delegate = self
            updatePostCell(cell, with: post)
            if let episode = post.episode {
                cell.imageContent?.setImageFrom(urlString: episode.imageURLString(), animated: true)
            }
            cell.layoutIfNeeded()
            return cell
            
        } else if let replies = post.replies where indexPath.row <= replies.count {
            let comment = replies[indexPath.row - 1] as! Postable
            
            var reuseIdentifier = ""
            if comment.images != nil || comment.youtubeID != nil {
                // Comment image cell
                reuseIdentifier = "CommentImageCell"
            } else {
                // Text comment update
                reuseIdentifier = "CommentTextCell"
            }
            
            let cell = tableView.dequeueReusableCellWithIdentifier(reuseIdentifier) as! CommentCell
            cell.delegate = self
            updateCommentCell(cell, with: comment)
            cell.layoutIfNeeded()
            return cell
            
        } else {
            
            // Write a comment cell
            let cell = tableView.dequeueReusableCellWithIdentifier("WriteACommentCell") as! WriteACommentCell
            cell.layoutIfNeeded()
            return cell
            
        }
        
    }
    
    func updatePostCell(cell: PostCell, with post: Postable) {
        if let postedBy = post.postedBy, let avatarFile = postedBy.avatarThumb {
            cell.avatar.setImageWithPFFile(avatarFile)
            cell.username.text = postedBy.aozoraUsername
        }
        
        cell.date.text = post.createdDate?.timeAgo()
        
        if var postedAgo = cell.date.text where post.edited {
            postedAgo += " · Edited"
            cell.date.text = postedAgo
        }
        
        cell.textContent.text = post.content
        if let replies = post.replies where replies.count > 0 {
            let buttonTitle = replies.count > 1 ? " \(replies.count) Comments" : " 1 Comment"
            cell.replyButton.setTitle(buttonTitle, forState: .Normal)
        } else {
            cell.replyButton.setTitle(" Comment", forState: .Normal)
        }
        
        updateAttributedTextProperties(cell.textContent)
        if let image = post.images?.first {
            cell.imageContent?.setImageFrom(urlString: image, animated: true)
        }
        
        prepareForVideo(cell.playButton, imageView: cell.imageContent, post: post)
    }
    
    func updateCommentCell(cell: CommentCell, with post: Postable) {
        
        
        if let postedBy = post.postedBy, let avatarFile = postedBy.avatarThumb {
            let username = postedBy.aozoraUsername
            let content = username + " " + post.content
            cell.avatar.setImageWithPFFile(avatarFile)
            
            updateAttributedTextProperties(cell.textContent)
            cell.textContent.setText(content, afterInheritingLabelAttributesAndConfiguringWithBlock: { (attributedString) -> NSMutableAttributedString! in
                
                return attributedString
            })
            
            let url = NSURL(string: "aozoraapp://profile/"+username)
            let range = (content as NSString).rangeOfString(username)
            cell.textContent.addLinkToURL(url, withRange: range)
        }
        
        cell.date.text = post.createdDate?.timeAgo()
        
        if var postedAgo = cell.date.text where post.edited {
            postedAgo += " · Edited"
            cell.date.text = postedAgo
        }
        
        if let image = post.images?.first {
            cell.imageContent?.setImageFrom(urlString: image, animated: true)
        }
        prepareForVideo(cell.playButton, imageView: cell.imageContent, post: post)
    }
    
    func prepareForVideo(playButton: UIButton?, imageView: UIImageView?, post: Postable) {
        if let playButton = playButton {
            if let youtubeID = post.youtubeID {
                
                let urlString = "https://i.ytimg.com/vi/\(youtubeID)/mqdefault.jpg"
                imageView?.setImageFrom(urlString: urlString, animated: true)
                
                playButton.hidden = false
                playButton.layer.borderWidth = 1.0;
                playButton.layer.borderColor = UIColor(white: 1.0, alpha: 0.5).CGColor;
            } else {
                playButton.hidden = true
            }
        }
    }
    
    func updateAttributedTextProperties(textContent: TTTAttributedLabel) {
        textContent.linkAttributes = [kCTForegroundColorAttributeName: UIColor.peterRiver()]
        textContent.enabledTextCheckingTypes = NSTextCheckingType.Link.rawValue
        textContent.delegate = self;
    }
}

extension ThreadViewController: UITableViewDelegate {
    public func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.1
    }
    
    public func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 5.0
    }
    
    public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let post = fetchController.objectAtIndex(indexPath.section) as! Postable
        
        if indexPath.row == 0 {
            showSheetFor(post: post)
        } else if let replies = post.replies where indexPath.row <= replies.count {
            if let comment = replies[indexPath.row - 1] as? Postable {
                showSheetFor(post: comment, parentPost: post)
            }
        } else {
            // Write a comment cell
            replyTo(post)
        }
    }
    
    func showSheetFor(#post: Postable, parentPost: Postable? = nil) {
        // If user's comment show delete/edit
        if post.postedBy == User.currentUser() {
            
            var alert = UIAlertController(title: "Manage Post", message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
            
            alert.addAction(UIAlertAction(title: "Edit", style: UIAlertActionStyle.Default, handler: { (alertAction: UIAlertAction!) -> Void in
                let comment = ANParseKit.commentViewController()
                if let post = post as? TimelinePost {
                    comment.initWithTimelinePost(self, editingPost: post)
                } else if let post = post as? Post, let thread = self.thread {
                    comment.initWithThread(thread, postType: self.postType, delegate: self, editingPost: post)
                }
                self.presentViewController(comment, animated: true, completion: nil)
            }))
            alert.addAction(UIAlertAction(title: "Delete", style: UIAlertActionStyle.Destructive, handler: { (alertAction: UIAlertAction!) -> Void in
                if let post = post as? PFObject {
                    if let parentPost = parentPost as? PFObject {
                        // Remove reference from parent
                        parentPost.removeObject(post, forKey: "replies")
                        parentPost.saveInBackgroundWithBlock({ (success, error) -> Void in
                            if let error = error {
                                // Show some error
                            } else {
                                self.deletePosts([post])
                            }
                        })
                    } else {
                        // Remove child too
                        let replies = post["replies"] as? [PFObject] ?? []
                        self.deletePosts(replies + [post])
                    }
                }
                
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler:nil))
            
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    func deletePosts(posts: [PFObject]) {
        PFObject.deleteAllInBackground(posts, block: { (success, error) -> Void in
            if let error = error {
                // Show some error
            } else {
                self.thread?.incrementKey("replies", byAmount: -posts.count)
                self.thread?.saveEventually()
                self.updateThread()
            }
        })
    }
}

extension ThreadViewController: FetchControllerDelegate {
    public func didFetchFor(#skip: Int) {
        refreshControl.endRefreshing()
    }
}

extension ThreadViewController: TTTAttributedLabelDelegate {
    
    public func attributedLabel(label: TTTAttributedLabel!, didSelectLinkWithURL url: NSURL!) {
        
        let (navController, webController) = ANCommonKit.webViewController()
        webController.initWithTitle(url.absoluteString!, initialUrl: url)
        presentViewController(navController, animated: true, completion: nil)
    }
}

extension ThreadViewController: CommentViewControllerDelegate {
    public func commentViewControllerDidFinishedPosting(post: PFObject) {
        updateThread()
    }
}

extension ThreadViewController: PostCellDelegate {
    public func postCellSelectedImage(postCell: PostCell) {
        if let post = postForCell(postCell), let imageView = postCell.imageContent {
            if let imageURL = post.images?.first {
                showImage(imageURL, imageView: imageView)
            } else if let videoID = post.youtubeID {
                playTrailer(videoID)
            }
        }
    }
    
    public func postCellSelectedUserProfile(postCell: PostCell) {
        if let post = postForCell(postCell), let postedByUser = post.postedBy {
            openProfile(postedByUser)
        }
    }
    
    public func postCellSelectedComment(postCell: PostCell) {
        if let post = postForCell(postCell) {
            replyTo(post)
        }
    }
}