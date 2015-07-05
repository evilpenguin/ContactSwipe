/*
 * ContactSwipe 
 * Created by James Emrich (EvilPenguin)
 * Version: 0.3.0
 *
 * Enjoy (<>..<>)
 *
 */

#import <AddressBook/AddressBook.h>
#import "ContactsSwipe.h"

CGFloat const CSAnimationDuration       = 0.1894;
CGFloat const CSSwipeDistance           = 100.0f;
static UIImage *CSSwipePhoneImage       = [UIImage imageWithContentsOfFile:@"/Library/Application Support/ContactSwipe/contactswipe_phone@2x.png"];
NSUInteger const CSSwipeViewTag         = 0xAF;

#pragma mark - == ABMemberCell Hooking ==

%hook ABMemberCell

- (id) initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    UITableViewCell *org = %orig;
    return org;
}

- (void) didMoveToSuperview {
    %orig;
   
    // Add our ContactSwipe views below the `contentView` :)
    if ([self viewWithTag:CSSwipeViewTag] == nil) {
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, CSSwipeDistance, self.bounds.size.height - 1.0f)];
        view.backgroundColor = [UIColor colorWithRed:0.70f green:0.70f blue:0.70f alpha:1.0f];
        view.tag = CSSwipeViewTag;

        UIImageView *phoneImageView = [[UIImageView alloc] initWithImage:CSSwipePhoneImage];
        phoneImageView.frame = CGRectMake(view.bounds.size.width - 30.0f, (view.bounds.size.height - 25.0f) / 2.0f, 25.0f, 25.0f);
        [view addSubview:phoneImageView];
        [phoneImageView release];

        [self insertSubview:view belowSubview:self.contentView];
        [view release];
    }
    
    self.contentView.backgroundColor = [UIColor whiteColor];
}

#pragma mark - == Touch Methods ==

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [[self viewWithTag:CSSwipeViewTag] setHidden:YES];
    self.highlighted = YES;
}

- (void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {  
    // Remove the highlight when we start to drag
    self.highlighted = NO;
    ((UIScrollView *)self.superview.superview).scrollEnabled = NO;
    [[self viewWithTag:CSSwipeViewTag] setHidden:NO];

    // Get our touch information
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInView:self.contentView];
    CGPoint previousLocation = [touch previousLocationInView:self.contentView];
    
    // Handle making the new frame
    CGRect newFrame = CGRectOffset(self.contentView.frame, (location.x - previousLocation.x), 0.0f);
    if (newFrame.origin.x < 0.0f) newFrame.origin.x = 0.0f;
    if (newFrame.origin.x >= CSSwipeDistance) newFrame.origin.x = CSSwipeDistance;
    self.contentView.frame = newFrame;

    %orig;
}

- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    self.highlighted = NO;
    ((UIScrollView *)self.superview.superview).scrollEnabled = YES;
    
    UIView *csView = [self viewWithTag:CSSwipeViewTag];
    if (csView.hidden) {
        // Handle calling the delegate to show the contacts view
        if (self.contentView.frame.origin.x == 0.0f) {
            csView.hidden = YES;

            UITableView *tableView = [self _tableView];
            if (tableView != nil && tableView.delegate != nil) {
                [tableView.delegate tableView:tableView didSelectRowAtIndexPath:[tableView indexPathForCell:self]];
            }   
        }
    }
    else {
        // Animate cell back, and decide if we make the call or not
        BOOL callContact = (self.contentView.frame.origin.x >= CSSwipeDistance);
        [self animateCellBackWithCall:callContact];
    }

    %orig;
}

- (void) touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    self.highlighted = NO;
    ((UIScrollView *)self.superview.superview).scrollEnabled = YES;
    [self animateCellBackWithCall:NO];

    %orig;
}

#pragma mark - == Private Methpds ==

%new
- (void) callPerson {
    if (self.person != NULL && self.person.record != nil) {
        ABMultiValueRef phones = ABRecordCopyValue(self.person.record, kABPersonPhoneProperty);
        if (phones != NULL && ABMultiValueGetCount(phones) > 0) {
            CFStringRef number = (CFStringRef)ABMultiValueCopyValueAtIndex(phones, 0);
            if (number != NULL && CFStringGetLength(number) > 0) {
                NSString *tempNumber = (NSString *)number;
                tempNumber = [tempNumber stringByReplacingOccurrencesOfString:@"-" withString:@""];
                tempNumber = [tempNumber stringByReplacingOccurrencesOfString:@"(" withString:@""];
                tempNumber = [tempNumber stringByReplacingOccurrencesOfString:@")" withString:@""];
                tempNumber = [tempNumber stringByReplacingOccurrencesOfString:@" " withString:@""];
                
                // Call tel:// with our number :)
                NSURL *numberUrl = [NSURL URLWithString:[@"tel://" stringByAppendingString:tempNumber]];
                [[UIApplication sharedApplication] openURL:numberUrl];
                
                CFRelease(number);
            }
            
            CFRelease(phones);
        }
    }
}

%new
- (void) animateCellBackWithCall:(BOOL)call {
    CGRect frame = self.contentView.frame;
    if (frame.origin.x > 0.0f) {
        frame.origin.x = 0.0f;
        [UIView animateWithDuration:CSAnimationDuration 
                         animations:^(void) {
                            self.contentView.frame = frame;
                         } 
                         completion:^(BOOL finished) {
                            if (call)[self callPerson];
                         }];
    }
}

%end

