//
//  InfiniteScrollController.m
//  Fun App
//
//  Created by Joseph Perla on 4/3/12.
//  Copyright (c) 2012 Ivy Call, LLC. All rights reserved.
//

#import "InfiniteScrollController.h"
#import "AppDelegate.h"

#define CELL_HEIGHT 40

@implementation InfiniteScrollController

@synthesize parentNavigationController;
@synthesize numRowsToReturn;
@synthesize infiniteScrollLock;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        self.numRowsToReturn = 100;
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    

    UISwipeGestureRecognizer *swipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeLeft:)];
    swipeLeft.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.view addGestureRecognizer:swipeLeft];
    
    
    UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRight:)];
    swipeLeft.direction = UISwipeGestureRecognizerDirectionRight;
    [self.view addGestureRecognizer:swipeRight];
    

    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return self.numRowsToReturn;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if ([AppDelegate isIpad]) {
        return 2 * CELL_HEIGHT;
    } else {
        return CELL_HEIGHT;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    NSInteger row = indexPath.row;
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    cell.frame = CGRectMake(0, 0, 300, CELL_HEIGHT);
    
    UILabel *textLabel = [[UILabel alloc] initWithFrame:cell.bounds];
    textLabel.text = [NSString stringWithFormat:@"Row %d", row];
    int fontSize = (CELL_HEIGHT - 10);
    if ([AppDelegate isIpad]) {
        fontSize = (fontSize * 2) - 10;
    }
    textLabel.font = [textLabel.font fontWithSize:fontSize];
    
    [cell addSubview:textLabel];
    
    // Configure the cell...
    
    if (row == (self.numRowsToReturn - 30)) {
        //load data
        self.numRowsToReturn += 100;
        NSLog(@"This is infinite.");
        [self.tableView performSelectorInBackground:@selector(reloadData) withObject:nil];
        //[self.tableView reloadData];
    }
    
    return cell;
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return NO;
}

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    
    InfiniteScrollController *detailViewController = [[InfiniteScrollController alloc] initWithStyle:UITableViewStylePlain];
   
    detailViewController.view.alpha = 0.2;
    [detailViewController.view setBackgroundColor:[UIColor yellowColor]];
    detailViewController.parentNavigationController = self.parentNavigationController;
     
     // ...
     // Pass the selected object to the new view controller.
     [self.parentNavigationController pushViewController:detailViewController animated:YES];

    
}

-(void) swipeLeft:(UISwipeGestureRecognizer *)gesture {
    [self tableView:self.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathWithIndex:3]];
}

-(void) swipeRight:(UISwipeGestureRecognizer *)gesture {
    [self.parentNavigationController popViewControllerAnimated:YES];
}

@end
