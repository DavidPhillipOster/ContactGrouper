//  ContactGroupViewController.m
//
//  by David Phillip Oster © 2021 All Rights Reserved on 11/5/21.
//

#import "ContactGroupViewController.h"

#import "CNContactStore+Additions.h"
#import "ContactSectionModel.h"
#import "GroupCell.h"
#import "GroupModel.h"
#import "RootView.h"

#import <Contacts/Contacts.h>

/// add a non-empty string to the array. Ignore nulls and empty strings.
static void Append(NSMutableArray *a, NSString *s){
  if (s.length) {
    [a addObject:s];
  }
}

/// Theory of operation:
/// show the contacts plus all the groups with on off switches.
/// as the user toggles the on-off switch, update the address book and data in RAM.
@interface ContactGroupViewController () <SwitchDelegate, UITableViewDataSource, UITableViewDelegate>

@property(nonatomic) UITableView *contactTableView;

@property(nonatomic) UITableView *groupTableView;

@property(nonatomic) UILabel *contactLabel;

@property(nonatomic) CNContact *currentContact;

/// All the contacts in the default collection in order.
@property(nonatomic) NSArray<CNContact *> *contactsInDefaultCollection;

/// Drives the Contact TableView U.I. alphabetic sections of contacts.
@property(nonatomic) NSArray<ContactSectionModel *> *sections;

/// Drives the Group TableView U.I. all the groups and their members
@property(nonatomic) NSArray<GroupModel *> *allGroups;

/// Connects the actual address book.
@property(nonatomic) CNContactStore *store;

/// For the address strip in the Contacts tableview.
@property(nonatomic) NSArray<NSString *> *sectionIndexTitles;

@end

@implementation ContactGroupViewController

- (void)loadView {
  CGRect bounds = UIScreen.mainScreen.bounds;
  RootView *view = [[RootView alloc] initWithFrame:bounds];
  if (@available(iOS 13, *)) {
    view.backgroundColor = UIColor.systemBackgroundColor;
  } else {
    view.backgroundColor = UIColor.whiteColor;
  }
  UITableView *tableView = [[UITableView alloc] initWithFrame:bounds style:UITableViewStylePlain];
  tableView.delegate = self;
  tableView.dataSource = self;
  view.contactTableView = tableView;
  self.contactTableView = tableView;
  [view addSubview:tableView];
  UILabel *contactLabel = [[UILabel alloc] init];
  contactLabel.numberOfLines = 0;
  view.contactLabel = contactLabel;
  self.contactLabel = contactLabel;
  [view addSubview:contactLabel];
  UITableView *groupTableView = [[UITableView alloc] initWithFrame:bounds style:UITableViewStylePlain];
  groupTableView.delegate = self;
  groupTableView.dataSource = self;
  view.groupTableView = groupTableView;
  self.groupTableView = groupTableView;
  [view addSubview:groupTableView];
  self.view = view;
  // In split screen mode, some other app could create, destroy, or modify users or groups.
  NSNotificationCenter *nc = NSNotificationCenter.defaultCenter;
  [nc addObserver:self selector:@selector(reinitModel:) name:CNContactStoreDidChangeNotification object:nil];
}

- (void)viewDidLoad {
  [super viewDidLoad];
  [self.groupTableView registerNib:[UINib nibWithNibName:@"GroupCell" bundle:nil]
  forCellReuseIdentifier:@"GroupCell"];
  self.contactTableView.sectionIndexMinimumDisplayRowCount = 3;
  [self.view setNeedsLayout];
}

// Does the work of fetching all the groups and all the discrete contacts within those groups.
- (void)initializeModel {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    [self reinitModel:nil];
  });
}

- (void)reinitModel:(NSNotification *)unused {
  dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0), ^{
    NSError *error = nil;
    NSArray<CNGroup *> *groups = [[self.store groupsMatchingPredicate:nil error:&error] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id  obj2) {
      CNGroup *g1 = obj1;
      CNGroup *g2 = obj2;
      return [g1.name caseInsensitiveCompare: g2.name];
    }];
    if (error) {
      [self presentError:error];
    }
    NSMutableArray<NSString *> *contactIDs = [NSMutableArray array];
    NSPredicate *collectionPredicate =  [CNContact predicateForContactsInContainerWithIdentifier:self.store.defaultContainerIdentifier];
    NSArray *keys = @[CNContactIdentifierKey,
        CNContactNamePrefixKey,
        CNContactGivenNameKey,
        CNContactMiddleNameKey,
        CNContactFamilyNameKey,
        CNContactNameSuffixKey,
        CNContactOrganizationNameKey,
    ];
    NSArray<CNContact *> *contactsInDefaultCollection = [self.store cg_discreteContactsMatchingPredicate:collectionPredicate keysToFetch:keys error:&error];
    contactsInDefaultCollection = [contactsInDefaultCollection sortedArrayUsingComparator:^(id obj1, id obj2) {
      CNContact *a = obj1;
      CNContact *b = obj2;
      NSString *aS = [a familyName];
      if (0 == aS.length) {
        aS = [a organizationName];
      }
      NSString *bS = [b familyName];
      if (0 == bS.length) {
        bS = [b organizationName];
      }
      NSComparisonResult result = [aS caseInsensitiveCompare:bS];
      if (NSOrderedSame == result) {
        aS = [a givenName];
        bS = [b givenName];
        result = [aS caseInsensitiveCompare:bS];
      }
      return result;
    }];
    for (CNContact *contact in contactsInDefaultCollection) {
       [contactIDs addObject:contact.identifier];
    }
    NSSet *contactSet = [NSSet setWithArray:contactIDs];

    NSMutableArray<GroupModel *> *allGroups = [NSMutableArray array];
    for (CNGroup *group in groups) {
      GroupModel *gm = [[GroupModel alloc] init];
      gm.group = group;
      NSPredicate *predicate = [CNContact predicateForContactsInGroupWithIdentifier:group.identifier];
      NSArray<CNContact *> *contacts = [self.store cg_discreteContactsMatchingPredicate:predicate keysToFetch:@[CNContactIdentifierKey] error:&error];
      if (error) {
        [self presentError:error];
        break;
      }
      NSMutableArray<NSString *> *ids = [NSMutableArray array];
      for (CNContact *contact in contacts) {
        NSString *identifier = contact.identifier;
        if ([contactSet containsObject:identifier]) {
          [ids addObject:identifier];
        }
      }
      gm.contactIDs = ids;
      [allGroups addObject:gm];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
      self.contactsInDefaultCollection = contactsInDefaultCollection;
      self.allGroups = allGroups;
      [self reloadData];
      // todo: take down any "please wait" U.I.
    });
  });
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  CNAuthorizationStatus status = [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts];
  if (CNAuthorizationStatusAuthorized == status) {
    [self initializeModel];
  } else if (CNAuthorizationStatusNotDetermined == status) {
    [self.store requestAccessForEntityType:CNEntityTypeContacts completionHandler:^(BOOL granted, NSError *error){
      dispatch_async(dispatch_get_main_queue(), ^{
        if(error) {
          [self presentError:error];
        } else if (granted) {
          [self initializeModel];
        } else {
          [self presentNotAuthorized];
        }
      });
    }];
  } else {
    [self presentNotAuthorized];
  }
}

// Initialize our master model: all groups, then for each group all discrete contacts within that group. return a place holder value until then.
- (NSArray<GroupModel *> *)allGroups {
  if (nil == _allGroups) {
    [self initializeModel];
  }
  return _allGroups;
}

- (CNContactStore *)store {
  if (nil == _store) {
    _store = [[CNContactStore alloc] init];
  }
  return _store;
}

- (void)presentNotAuthorized {
  dispatch_async(dispatch_get_main_queue(), ^{
    NSString *title = NSLocalizedString(@"ContactsDenied", @"0");
    NSString *suggestion = NSLocalizedString(@"ContactsSuggestion", 0);
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:suggestion
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *settingsAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Settings", @"")
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * _Nonnull action) {
      NSURL *URL = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
      [UIApplication.sharedApplication openURL:URL options:@{} completionHandler:nil];
    }];
    [alert addAction:settingsAction];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"")
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction * _Nonnull action) {
      [alert dismissViewControllerAnimated:YES completion:nil];
    }];
    [alert addAction:okAction];
    [alert setPreferredAction:okAction];
    [self presentViewController:alert animated:YES completion:nil];
  });
}

- (void)presentError:(NSError *)error {
  dispatch_async(dispatch_get_main_queue(), ^{
    [self presentErrorOnMainQueue:error];
  });
}

- (void)presentErrorOnMainQueue:(NSError *)error {
  NSString *s = error.userInfo[NSLocalizedDescriptionKey];
  if (0 == s.length) {
    s = error.description;
  }
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:s message:@"" preferredStyle:UIAlertControllerStyleAlert];
  [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
    [alert dismissViewControllerAnimated:YES completion:nil];
  }]];
  [self presentViewController:alert animated:YES completion:nil];
}

- (void)rebuildSections {
  NSMutableArray<ContactSectionModel *> *sections = [NSMutableArray array];
  NSString *last = @"";
  ContactSectionModel *currentSection = nil;
  NSMutableArray<CNContact *> *contacts = nil;
  for (CNContact *contact in self.contactsInDefaultCollection) {
    NSString *lastName = contact.familyName;
    if (lastName.length == 0) {
      lastName = contact.organizationName;
    }
    if (lastName.length != 0) {
      NSString *prefix = [[lastName substringToIndex:1] uppercaseString];
      if ( ! [prefix isEqual:last] ) {
        last = prefix;
        if (nil != currentSection) {
          [sections addObject:currentSection];
        }
        currentSection = [[ContactSectionModel alloc] init];
        contacts = [NSMutableArray array];
        currentSection.contacts = contacts;
        currentSection.title = prefix;
      }
      [contacts addObject:contact];
    }
  }
  if (nil != currentSection && 0 != contacts) {
    currentSection.contacts = contacts;
    [sections addObject:currentSection];
    currentSection = nil;
  }
  self.sections = sections;
}

- (void)reloadData {
  [self rebuildSections];
  [self.contactTableView reloadData];
  [self.groupTableView reloadData];
}

#pragma mark - SwitchDelegate

- (void)cellDidChange:(GroupCell *)cell {
  CNContact *contact = self.currentContact;
  if (nil == contact) {
    return;
  }
  GroupModel *groupModel = self.allGroups[cell.groupIndex];
  NSMutableArray<NSString *> *mutableContacts = [groupModel.contactIDs mutableCopy];
  CNSaveRequest *request = [[CNSaveRequest alloc] init];
  if (cell.isMember.isOn) {
    [mutableContacts addObject:contact.identifier];
    [request addMember:contact toGroup:groupModel.group];
  } else {
    [mutableContacts removeObject:contact.identifier];
    [request removeMember:contact fromGroup:groupModel.group];
  }
  dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0), ^{
    NSError *error = nil;
    if ([self.store executeSaveRequest:request error:&error]) {
      groupModel.contactIDs = mutableContacts;  // It worked. update the model to match U.I. state.
    } else {
      NSIndexPath *path = [NSIndexPath indexPathForRow:cell.groupIndex inSection:0];
      dispatch_async(dispatch_get_main_queue(), ^{
        if (contact == self.currentContact) {
          // It failed. update the U.I. to match model state.
          [self.contactTableView reloadRowsAtIndexPaths:@[path] withRowAnimation:NO];
        }
      });
      [self presentError:error];
    }
  });
}

#pragma mark - TableViewDelegate

- (nullable NSArray<NSString *> *)sectionIndexTitlesForTableView:(UITableView *)tableView {
  if (tableView != self.contactTableView) {
    return nil;
  }
  NSMutableArray *stripItems = [NSMutableArray array];
  for (ContactSectionModel *section in self.sections) {
    [stripItems addObject:section.title];
  }
  return stripItems;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
  if (0 <= index && index < [self.sections count]) {
    return index;
  }
  return 0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  if (self.contactTableView == tableView) {
    return self.sections.count;
  } else {
    return 1;
  }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  if (self.contactTableView == tableView) {
    ContactSectionModel *contactSection = self.sections[section];
    return contactSection.contacts.count;
  } else {
    return self.allGroups.count;
  }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
  if (self.contactTableView == tableView) {
    ContactSectionModel *contactSection = self.sections[section];
    return contactSection.title;
  } else {
    return nil;
  }
}

- (UITableViewCell *)contactCell:(nonnull NSIndexPath *)indexPath {
  UITableViewCell *cell = [self.contactTableView dequeueReusableCellWithIdentifier:@"contact"];
  if (nil == cell) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"contact"];
  }
  ContactSectionModel *contactSection = self.sections[indexPath.section];
  CNContact *contact = contactSection.contacts[indexPath.row];
  NSMutableArray *a = [NSMutableArray array];
  Append(a,[contact namePrefix]);
  Append(a,[contact givenName]);
  Append(a,[contact middleName]);
  Append(a,[contact familyName]);
  Append(a,[contact nameSuffix]);
  Append(a,[contact organizationName]);
  cell.textLabel.text = [a componentsJoinedByString:@" "];
  return cell;
}

- (GroupCell *)groupCell:(nonnull NSIndexPath *)indexPath {
  GroupCell *cell = (GroupCell *)[self.groupTableView dequeueReusableCellWithIdentifier:@"GroupCell" forIndexPath:indexPath];
  cell.selectionStyle = UITableViewCellSelectionStyleNone;
  cell.delegate = self;
  cell.groupIndex = indexPath.row;

  GroupModel *thisGroup = self.allGroups[cell.groupIndex];
  cell.title.text = thisGroup.group.name;
  BOOL enabled = (nil != self.currentContact);
  cell.isMember.enabled = enabled;
  if (enabled) {
    if (@available(iOS 13.0, *)) {
      cell.title.textColor = UIColor.labelColor;
    } else {
      cell.title.textColor = UIColor.blackColor;
    }
    cell.isMember.on = [thisGroup.contactIDs containsObject:self.currentContact.identifier];
  } else {
    cell.title.textColor = UIColor.darkGrayColor;
    cell.isMember.on = NO;
  }
  return cell;
}

// if we have N groups, then for each contact, there are N+1 cells: the name of the contact followed by its groups.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
  if (self.contactTableView == tableView) {
    return [self contactCell:indexPath];
  } else {
    return [self groupCell:indexPath];
  }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  if (self.contactTableView == tableView) {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    ContactSectionModel *contactSection = self.sections[indexPath.section];
    self.currentContact = contactSection.contacts[indexPath.row];
    self.contactLabel.text = cell.textLabel.text;
    [self.groupTableView reloadData];
  }
}

@end
