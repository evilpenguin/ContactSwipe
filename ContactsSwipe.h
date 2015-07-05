
#pragma mark - == Interfaces ==

@interface ABUIPerson : NSObject {

}
@property(readonly) void* record;

@end

@interface ABMemberCell : UITableViewCell {
    
}
@property(retain) ABUIPerson * person;


- (UITableView *) _tableView;
- (void) callPerson;
- (void) animateCellBackWithCall:(BOOL)call;

@end


@interface ABMembersDataSource : NSObject <UITableViewDelegate, UITableViewDataSource> {

}

- (void)tableView:(id)arg1 didSelectRowAtIndexPath:(id)arg2;

@end