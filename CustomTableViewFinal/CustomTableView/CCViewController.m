//
//  CCViewController.m
//  CodeChallengeApp
//
//  Created by Shubhangi Acharya on 12/04/14.
//  Copyright (c) 2014 CodeChallenge. All rights reserved.
//

#import "CCViewController.h"

@interface CCViewController ()
@property (nonatomic, strong) NSArray *timelineData;
@property (nonatomic, strong) NSArray *timelineUserData;
@property (nonatomic, strong) NSArray *timelineSourceData;
@property (nonatomic, strong) NSArray *timelineTextData;


@end

@implementation CCViewController

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.title = @"Code Challenge";
    [self setupView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Instance methods

- (void)setupView {
    // Remove table cell separator
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    
    // Assign our own backgroud for the view
    self.parentViewController.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"common_bg"]];
    self.tableView.backgroundColor = [UIColor clearColor];
    
    // Add padding to the top of the table view
    UIEdgeInsets inset = UIEdgeInsetsMake(5, 0, 0, 0);
    self.tableView.contentInset = inset;
    // Adding pull to refresh control
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc]
                                        init];
    refreshControl.tintColor = [UIColor magentaColor];
    [refreshControl addTarget:self action:@selector(changeSorting) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;
    // Calling method to fetch timeline data
    [self fetchTimeline];
}

- (void)changeSorting {
    [self fetchTimeline];
    [self.refreshControl endRefreshing];
}

- (void)fetchTimeline {
    NSURL *url = [NSURL URLWithString:@"https://alpha-api.app.net/stream/0/posts/stream/global"];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [NSURLConnection sendAsynchronousRequest:request
                       queue:[NSOperationQueue mainQueue]
           completionHandler:^(NSURLResponse *response,
                               NSData *data, NSError *connectionError) {
               if (data.length > 0 && connectionError == nil) {
                   NSDictionary *fetchedData = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
                   self.timelineData = [fetchedData valueForKey:@"data"];
                   NSSortDescriptor *sd = [NSSortDescriptor sortDescriptorWithKey:@"created_at" ascending:NO];
                   NSArray *sortedByTime = [self.timelineData sortedArrayUsingDescriptors:@[sd]];
                   self.timelineUserData = [sortedByTime valueForKey:@"user"];
                   self.timelineSourceData = [sortedByTime valueForKey:@"source"];
                [self.tableView reloadData];
               }
           }];
}

- (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
    UIGraphicsBeginImageContext(newSize);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [self.timelineData count];
}

- (UIImage *)cellBackgroundForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger rowCount = [self tableView:[self tableView] numberOfRowsInSection:0];
    NSInteger rowIndex = indexPath.row;
    UIImage *background = nil;
    
    if (rowIndex == 0) {
        background = [UIImage imageNamed:@"cell_top.png"];
    } else if (rowIndex == rowCount - 1) {
        background = [UIImage imageNamed:@"cell_bottom.png"];
    } else {
        background = [UIImage imageNamed:@"cell_middle.png"];
    }
    
    return background;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[NSString stringWithFormat:@"%d", indexPath.row]];
    
    // Configure the cell...
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:[NSString stringWithFormat:@"%d", indexPath.row]];
    }
    
    NSArray *avatarToDisplay = [NSMutableArray array];
    avatarToDisplay = [[self.timelineUserData objectAtIndex:indexPath.row] valueForKey:@"avatar_image"];
    
    // Async Image loading
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData *imgData = [NSData dataWithContentsOfURL:[NSURL URLWithString:[avatarToDisplay valueForKey:@"url"]]];
        if (imgData) {
            UIImage *image = [UIImage imageWithData:imgData];
            if (image) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    UITableViewCell *blockCell = [tableView cellForRowAtIndexPath:indexPath];
                    if (blockCell) {
                        UIImage *thumbImage = [self imageWithImage:image scaledToSize:CGSizeMake(50, 50)];
                        blockCell.imageView.image = thumbImage;
                    [cell setNeedsLayout];
                    }
                });
            }
        }
    });
    
    // Code for rounded corners.
    cell.imageView.contentMode =  UIViewContentModeScaleAspectFill;
    cell.imageView.layer.cornerRadius = 16;
    cell.imageView.clipsToBounds = YES;
    
    // Name text
    cell.textLabel.text = [[self.timelineSourceData objectAtIndex:indexPath.row] valueForKey:@"name"];
    
    // Text with dynamic size
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString: [[self.timelineData objectAtIndex:indexPath.row ] valueForKey:@"text"]];
    [attributedString setAttributes:@{NSBackgroundColorAttributeName:[UIColor whiteColor]} range:NSMakeRange(0, attributedString.length)];
    [attributedString setAttributes:@{NSForegroundColorAttributeName:[UIColor colorWithWhite:0.23 alpha:1.0]} range:NSMakeRange(0, attributedString.length)];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setLineBreakMode:NSLineBreakByWordWrapping];
    [attributedString setAttributes:@{NSParagraphStyleAttributeName:paragraphStyle} range:NSMakeRange(0, attributedString.length)];
    [attributedString setAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:12]} range:NSMakeRange(0, attributedString.length)];
    cell.detailTextLabel.attributedText = attributedString;
    CGRect boundingRect = [attributedString boundingRectWithSize:CGSizeMake(cell.detailTextLabel.frame.size.width, 2000.0f) options:NSStringDrawingUsesLineFragmentOrigin context:nil];
    cell.detailTextLabel.frame = CGRectMake(cell.detailTextLabel.frame.origin.x, cell.detailTextLabel.frame.origin.y, boundingRect.size.width, boundingRect.size.height);
    cell.detailTextLabel.numberOfLines = 0;
    cell.detailTextLabel.lineBreakMode = NSLineBreakByWordWrapping;
    
    
    // Assigning my own background image for the cell to make it nice
    UIImage *background = [self cellBackgroundForRowAtIndexPath:indexPath];
    UIImageView *cellBackgroundView = [[UIImageView alloc] initWithImage:background];
    cellBackgroundView.image = background;
    cell.backgroundView = cellBackgroundView;

    return cell;
}

#pragma mark - Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITextView *calculationView = [[UITextView alloc] init];
    [calculationView setAttributedText:[[NSMutableAttributedString alloc] initWithString: [[self.timelineData objectAtIndex:indexPath.row ] valueForKey:@"text"]]];
    CGSize size = [calculationView sizeThatFits:CGSizeMake(120, FLT_MAX)];
    return size.height + 10;
}


@end
