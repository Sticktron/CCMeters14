//
//  CCMeters14ViewController.m
//  CCMeters14
//
//  Copyright © 2024 Sticktron. All rights reserved.
//

#define DEBUG_PREFIX @" [CCMeters14ViewController] >> "
#import "DebugLog.h"

#import "CCMeters14ViewController.h"
#import "Meter.h"

#import <sys/socket.h>
#import <sys/sysctl.h>
#import <sys/types.h>
#import <mach/mach_host.h>
#import <mach/mach_time.h>
#import <net/if.h>
#import <net/if_var.h>
#import <net/if_dl.h>

#import <ifaddrs.h>
#import <arpa/inet.h>
#import <SpringBoard/SBWiFiManager.h>
#import <SpringBoard/SpringBoard.h>
#import <objc/runtime.h>
#import <FrontBoardServices/FBSSystemService.h>
#import <spawn.h>

#define	RTM_IFINFO2			0x12 //from route.h

#define UPDATE_INTERVAL		2.0f

#define ICON_SIZE			24.0f
#define LABEL_HEIGHT		16.0f
#define SIDE_MARGIN	    	8.0f
#define TOGGLE_SIZE		    40.0f

#define ALERT_SHUT_DOWN		0

typedef struct {
    uint64_t totalSystemTime;
    uint64_t totalUserTime;
    uint64_t totalIdleTime;
} CPUSample;

typedef struct {
    uint64_t timestamp;
    uint64_t totalDownloadBytes;
    uint64_t totalUploadBytes;
} NetSample;

@interface UIImage (CCM)
+ (id)imageNamed:(id)name inBundle:(id)bundle;
@end

//------------------------------------------------------------------------------

@interface CCMeters14ViewController ()
@property (nonatomic, strong) Meter *cpuMeter;
@property (nonatomic, strong) Meter *ramMeter;
@property (nonatomic, strong) Meter *diskMeter;
@property (nonatomic, strong) Meter *uploadMeter;
@property (nonatomic, strong) Meter *downloadMeter;
@property (nonatomic, strong) NSMutableArray *meters;

@property (nonatomic, strong) NSTimer *meterUpdateTimer;

@property (nonatomic, assign) CPUSample lastCPUSample;
@property (nonatomic, assign) NetSample lastNetSample;

@property (nonatomic, strong) UIView *expandedView;
@property (nonatomic, strong) UILabel *wifiSSIDLabel;
@property (nonatomic, strong) UILabel *wifiIPLabel;
@property (nonatomic, strong) UILabel *tagLabel;

@property (nonatomic, strong) UIView *togglesView;
@property (nonatomic, strong) UIButton *respringButton;
@property (nonatomic, strong) UIButton *restartButton;
@property (nonatomic, strong) UIButton *restartUserspaceButton;

- (void)layoutCollapsedView;
@end

//------------------------------------------------------------------------------

@implementation CCMeters14ViewController

- (instancetype)init {
    if ((self = [super init])) {
        // create meters
        _cpuMeter = [[Meter alloc] initWithName:@"cpu" title:@"CPU"];
        _ramMeter = [[Meter alloc] initWithName:@"ram" title:@"RAM"];
        _diskMeter = [[Meter alloc] initWithName:@"disk" title:@"DISK"];
        _uploadMeter = [[Meter alloc] initWithName:@"upload" title:@"U/L"];
        _downloadMeter = [[Meter alloc] initWithName:@"download" title:@"D/L"];
        
        // store meters in order
        _meters = [NSMutableArray arrayWithArray:@[ _cpuMeter,
                                                    _ramMeter,
                                                    _diskMeter,
                                                    _uploadMeter,
                                                    _downloadMeter ]];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
    // SUPER-HACKY!! need this for the layer effect composition to work
    [self.view.layer setValue:@(NO) forKey:@"allowsGroupBlending"];
	
	[self setupCollapsedView];
	[self setupExpandedView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    DebugLog(@"viewWillAppear(animated:%d)", animated);
    DebugLog(@"expanded = %d)", self.expanded);
    
    // set expanded module width to match small size
    _preferredExpandedContentWidth = self.view.bounds.size.width;
    _preferredExpandedContentHeight = self.view.bounds.size.height * 3;
    
    [self layoutCollapsedView];
	
    [self startUpdating]; // start updating meters !!!
}

- (void)setupCollapsedView {
	for (Meter *meter in self.meters) {
        
		// create icon...
        UIButton *icon = [[UIButton alloc] init];
		icon.userInteractionEnabled = NO;
        NSBundle *bundle = [NSBundle bundleWithPath:@"/Library/ControlCenter/Bundles/CCMeters14.bundle"];
        UIImage *iconImage = [UIImage imageNamed:meter.name inBundle:bundle];
		iconImage = [iconImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
		[icon setImage:iconImage forState:UIControlStateNormal];
        icon.tintColor = UIColor.whiteColor;
        // icon.layer.compositingFilter = @"plusL";
        icon.layer.compositingFilter = @"linearDodgeBlendMode";
        icon.alpha = 0.5;
                
        // test border
        // icon.layer.borderWidth = 1;
        // icon.layer.borderColor = UIColor.greenColor.CGColor;
        [self.view addSubview:icon];
		meter.icon = icon;
        
		// create label...
        UILabel *label = [[UILabel alloc] init];
        // label.font = [UIFont systemFontOfSize:11 weight:UIFontWeightSemibold];
        label.font = [UIFont systemFontOfSize:10 weight:UIFontWeightSemibold];
		label.textAlignment = NSTextAlignmentCenter;
        label.textColor = UIColor.whiteColor;
		label.text = meter.title;
        // test border
        // label.layer.borderWidth = 1;
        // label.layer.borderColor = UIColor.greenColor.CGColor;
		[self.view addSubview:label];
		meter.label = label;
	}	
}

- (void)setupExpandedView {
    _expandedView = [[UIView alloc] init];
	//_expandedView.backgroundColor = [UIColor colorWithRed:1 green:0 blue:0 alpha:0.2];
    [self.view addSubview:_expandedView];
    
    // SSID
    _wifiSSIDLabel = [[UILabel alloc] init];
    _wifiSSIDLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightSemibold];
    _wifiSSIDLabel.textAlignment = NSTextAlignmentCenter;
    _wifiSSIDLabel.textColor = UIColor.whiteColor;
    [self.expandedView addSubview:_wifiSSIDLabel];
    
    // Wifi IP
    _wifiIPLabel = [[UILabel alloc] init];
    _wifiIPLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightSemibold];
    _wifiIPLabel.textAlignment = NSTextAlignmentCenter;
    _wifiIPLabel.textColor = UIColor.whiteColor;
    [self.expandedView addSubview:_wifiIPLabel];
    
    // tag
    _tagLabel = [[UILabel alloc] init];
    _tagLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightSemibold];
    _tagLabel.textAlignment = NSTextAlignmentCenter;
    _tagLabel.textColor = UIColor.whiteColor;
    _tagLabel.text = @"Made by Mike ♥︎";
    [self.expandedView addSubview:_tagLabel];
	
	
	// toggles...
	
	_togglesView = [[UIView alloc] init];
    //_togglesView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:1 alpha:0.2];
	
    // SUPER-HACKY!! need this for the layer effect composition to work
    [_togglesView.layer setValue:@(NO) forKey:@"allowsGroupBlending"];
	
	
	// Respring button
	_respringButton = [UIButton buttonWithType:UIButtonTypeCustom];
	//_respringButton.backgroundColor = UIColor.redColor;	
	_respringButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
	_respringButton.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
    _respringButton.tintColor = UIColor.whiteColor;
    _respringButton.layer.compositingFilter = @"linearDodgeBlendMode";
    _respringButton.alpha = 0.5;	
	UIImage *respringImage = [UIImage systemImageNamed:@"arrow.counterclockwise.circle.fill"];
	respringImage = [respringImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
	[_respringButton setImage:respringImage forState:UIControlStateNormal];
	[_respringButton addTarget:self action:@selector(respringButtonTapped) forControlEvents:UIControlEventTouchUpInside];	
	[_togglesView addSubview:_respringButton];
	
	// Restart Button
	_restartButton = [UIButton buttonWithType:UIButtonTypeCustom];
	//_restartButton.backgroundColor = UIColor.redColor;	
	_restartButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
	_restartButton.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;	
    _restartButton.tintColor = UIColor.whiteColor;
    _restartButton.layer.compositingFilter = @"linearDodgeBlendMode";
    _restartButton.alpha = 0.5;	
	UIImage *restartImage = [UIImage systemImageNamed:@"arrow.triangle.2.circlepath.circle.fill"];
	restartImage = [restartImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
	[_restartButton setImage:restartImage forState:UIControlStateNormal];
	[_restartButton addTarget:self action:@selector(restartButtonTapped) forControlEvents:UIControlEventTouchUpInside];
	[_togglesView addSubview:_restartButton];
	
	// Restart Userspace Button
	_restartUserspaceButton = [UIButton buttonWithType:UIButtonTypeCustom];
	_restartUserspaceButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
	_restartUserspaceButton.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;	
    _restartUserspaceButton.tintColor = UIColor.whiteColor;
    _restartUserspaceButton.layer.compositingFilter = @"linearDodgeBlendMode";
    _restartUserspaceButton.alpha = 0.5;	
	UIImage *restartUserspaceImage = [UIImage systemImageNamed:@"exclamationmark.circle.fill"];
	restartUserspaceImage = [restartUserspaceImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
	[_restartUserspaceButton setImage:restartUserspaceImage forState:UIControlStateNormal];
	[_restartUserspaceButton addTarget:self action:@selector(restartUserspaceButtonTapped) forControlEvents:UIControlEventTouchUpInside];
	[_togglesView addSubview:_restartUserspaceButton];
	
	
	
	
	[self.expandedView addSubview:_togglesView];
}

- (void)controlCenterDidDismiss {
    DebugLog(@"controlCenterDidDismiss()");
	
	// stop updating meters !!!
    [self stopUpdating];
}

- (void)didTransitionToExpandedContentMode:(BOOL)expanded {
    DebugLog(@"didTransitionToExpandedContentMode(%d)", expanded);
    if (expanded) {
	    [self layoutExpandedView];
        [self updateExpandedContent];
        self.expandedView.hidden = NO;
    }
}

- (void)willTransitionToExpandedContentMode:(BOOL)expanded {
    DebugLog(@"willTransitionToExpandedContentMode(%d)", expanded);
    if (!expanded) {
        self.expandedView.hidden = YES;
    }
}

- (BOOL)_canShowWhileLocked {
	return YES;
}


//---------- Layout ------------------------------------------------------------

- (void)layoutCollapsedView {
    DebugLog(@"layoutCollapsedView()");
    DebugLog(@"self.view.frame = %@", NSStringFromCGRect(self.view.frame));
    
    // update visibility...
    NSMutableArray *visibleMeters = [NSMutableArray array];
    for (Meter *meter in self.meters) {
        if (meter.enabled) {
            meter.icon.hidden = NO;
            meter.label.hidden = NO;
            [visibleMeters addObject:meter];
        } else {
            meter.icon.hidden = YES;
            meter.label.hidden = YES;
        }
    }
        
    // update position...
    int count = (int)visibleMeters.count;
    if (count > 0) {
		int topMargin = (self.view.bounds.size.height - ICON_SIZE - LABEL_HEIGHT) / 2;
		int width = (self.view.bounds.size.width - (2*SIDE_MARGIN)) / count;
		int x = SIDE_MARGIN;
		for (Meter *meter in visibleMeters) {
			meter.icon.frame = CGRectMake(x, topMargin, width, ICON_SIZE);
			meter.label.frame = CGRectMake(x, topMargin + ICON_SIZE, width, LABEL_HEIGHT);
			x += width;
            //DebugLog(@"Layed out meter (%@): Icon = %@; Label = %@", meter.name, NSStringFromCGRect(meter.icon.frame), NSStringFromCGRect(meter.label.frame));
		}
    }
}

- (void)layoutExpandedView {
    float topMargin = 72;
	float height = self.view.bounds.size.height - topMargin;
	float width = self.view.bounds.size.width;
    
    self.expandedView.frame = CGRectMake(0, topMargin, width, height);
    DebugLog(@"self.view.frame = %@", NSStringFromCGRect(self.view.frame));
    DebugLog(@"self.expandedView.frame = %@", NSStringFromCGRect(self.expandedView.frame));
    	
    float spaceBetweenRows = 20;
    float y = spaceBetweenRows;
    
    self.wifiSSIDLabel.frame = CGRectMake(0, y, self.expandedView.bounds.size.width, LABEL_HEIGHT);
    y += spaceBetweenRows;
    self.wifiIPLabel.frame = CGRectMake(0, y, self.expandedView.bounds.size.width, LABEL_HEIGHT);
    // y += spaceBetweenRows;
    // y += spaceBetweenRows;
    // self.tagLabel.frame = CGRectMake(0, y, self.expandedView.bounds.size.width, LABEL_HEIGHT);
	
	CGRect frame = CGRectMake(0, height - TOGGLE_SIZE - 10, (3 * TOGGLE_SIZE) + 80, TOGGLE_SIZE + 10);
	self.togglesView.frame = frame;
	self.togglesView.center = CGPointMake(width / 2.0f, self.togglesView.center.y);
	self.respringButton.frame = CGRectMake(0, 0, TOGGLE_SIZE, TOGGLE_SIZE);
	self.restartButton.frame = CGRectMake(TOGGLE_SIZE + 40, 0, TOGGLE_SIZE, TOGGLE_SIZE);
	self.restartUserspaceButton.frame = CGRectMake(2 * TOGGLE_SIZE + 80, 0, TOGGLE_SIZE, TOGGLE_SIZE);
	
}

- (void)updateExpandedContent {
    self.wifiSSIDLabel.text = [NSString stringWithFormat:@"WiFi SSID: %@", [self wifiSSID]];
    self.wifiIPLabel.text = [NSString stringWithFormat:@"WiFi IP: %@", [self ipForInterface:@"en0"]];
}


//---------- Meters Stuff ------------------------------------------------------

- (void)startUpdating {
    DebugLog(@"startUpdating()");
    
    // bail if the meters are already running
    if ([self.meterUpdateTimer isValid]) {
        DebugLog(@"meters are already running, no need to start them again!");
        
    } else {
        // show placeholder values
        for (Meter *meter in self.meters) {
            meter.label.text = meter.title;
        }
        
        // get new starting measurements
        self.lastCPUSample = [self getCPUSample];
        self.lastNetSample = [self getNetSample];
        
        // start timer
        self.meterUpdateTimer = [NSTimer timerWithTimeInterval:UPDATE_INTERVAL target:self
													  selector:@selector(updateMeters:)
													  userInfo:nil
													   repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:self.meterUpdateTimer forMode:NSRunLoopCommonModes];
        DebugLog(@"••••• started Timer ••••• (%@)", self.meterUpdateTimer);
    }
}

- (void)stopUpdating {
    if (self.meterUpdateTimer) {
        DebugLog(@"••••• stopping Timer ••••• (%@)", self.meterUpdateTimer);
        [self.meterUpdateTimer invalidate];
        self.meterUpdateTimer = nil;
    }
}

- (void)updateMeters:(NSTimer *)timer {
    DebugLog(@"updateMeters called (timer %@)", timer);
    
    // Disk Meter: free space on /User
    if (self.diskMeter.enabled) {
        unsigned long long bytesFree = [self diskFreeInBytesForPath:@"/"];
        DebugLog(@"***** bytesFree = %llu", bytesFree);
        //unsigned long long bytesFree = [self diskFreeInBytesForPath:NSHomeDirectory()];
        double gigsFree = (double)bytesFree / (1024*1024*1024);
        [self.diskMeter.label setText:[NSString stringWithFormat:@"%.1f GB", gigsFree]];
    }
    
    // RAM Meter: "available" memory (free + inactive)
    if (self.ramMeter.enabled) {
        uint32_t ram = [self memoryAvailableInBytes];
        ram /= (1024*1024); // convert to MB
        [self.ramMeter.label setText:[NSString stringWithFormat:@"%u MB", ram]];
    }
    
    // CPU Meter: percentage of time in use since last sample
    if (self.cpuMeter.enabled) {
        CPUSample cpu_delta;
        CPUSample cpu_sample = [self getCPUSample];
        
        // get usage for period
        cpu_delta.totalUserTime = cpu_sample.totalUserTime - self.lastCPUSample.totalUserTime;
        cpu_delta.totalSystemTime = cpu_sample.totalSystemTime - self.lastCPUSample.totalSystemTime;
        cpu_delta.totalIdleTime = cpu_sample.totalIdleTime - self.lastCPUSample.totalIdleTime;
        
        // calculate time spent in use as a percentage of the total time
        uint64_t total = cpu_delta.totalUserTime + cpu_delta.totalSystemTime + cpu_delta.totalIdleTime;
        //		double idle = (double)(cpu_delta.totalIdleTime) / (double)total * 100.0; // in %
        //		double used = 100.0 - idle;
        double used = ((cpu_delta.totalUserTime + cpu_delta.totalSystemTime) / (double)total) * 100.0;
        
        [self.cpuMeter.label setText:[NSString stringWithFormat:@"%.1f %%", used]];
        
        // save this sample for next time
        self.lastCPUSample = cpu_sample;
    }
    
    
    // Net Meters: bandwidth used during sample period, normalized to per-second values
    if (self.uploadMeter.enabled || self.downloadMeter.enabled) {
        NetSample net_delta;
        NetSample net_sample = [self getNetSample];
        
        // calculate period length
        net_delta.timestamp = (net_sample.timestamp - self.lastNetSample.timestamp);
        double interval = net_delta.timestamp / 1000.0 / 1000.0 / 1000.0; // ns-to-s
        //DebugLog(@"Net Meters sample delta: %fs", interval);
        
        // get bytes transferred since last sample was taken
        net_delta.totalUploadBytes = net_sample.totalUploadBytes - self.lastNetSample.totalUploadBytes;
        net_delta.totalDownloadBytes = net_sample.totalDownloadBytes - self.lastNetSample.totalDownloadBytes;
        
        if (self.uploadMeter.enabled) {
            double ul = (double)net_delta.totalUploadBytes / interval;
            self.uploadMeter.label.text = [self formatBytes:ul];
        }
        
        if (self.downloadMeter.enabled) {
            double dl = net_delta.totalDownloadBytes / interval;
            self.downloadMeter.label.text = [self formatBytes:dl];
        }
        
        // save this sample for next time
        self.lastNetSample = net_sample;
    }
}

- (unsigned long long)diskFreeInBytesForPath:(NSString *)path {
    unsigned long long result = 0;
    NSDictionary *attr = [[NSFileManager defaultManager] attributesOfFileSystemForPath:path error:nil];
    if (attr && attr[@"NSFileSystemFreeSize"]) {
        result = [attr[@"NSFileSystemFreeSize"] longLongValue];
    }
    return result;
}

- (uint32_t)memoryAvailableInBytes {
	// I'm counting "available" as free + inactive memory
	
	uint32_t bytesAvailable = 0;
	
	// get page size
	vm_size_t pagesize = vm_kernel_page_size;
	//DebugLog(@"using page size of: %d bytes", (int)pagesize);
	
	// get stats
	kern_return_t kr;
	mach_msg_type_number_t count = HOST_VM_INFO_COUNT;
	vm_statistics_data_t vm_stat;
	
	kr = host_statistics(mach_host_self(), HOST_VM_INFO, (host_info_t)&vm_stat, &count);
	if (kr != KERN_SUCCESS) {
		DebugLog(@"error getting VM_INFO from host!!!");
		
	} else {
		unsigned long bytesInactive = vm_stat.inactive_count * pagesize;
		unsigned long bytesFree = vm_stat.free_count * pagesize;
		bytesAvailable = (uint32_t)(bytesFree + bytesInactive);
		//DebugLog(@"Got RAM stats: Free=%lu B; Inactive=%lu B; Total Available=%u B", bytesFree, bytesInactive, bytesAvailable);
	}
	
	return bytesAvailable;
}

- (CPUSample)getCPUSample {
    /*
     CPUSample: { totalUserTime, totalSystemTime, totalIdleTime }
     */
    CPUSample sample = {0, 0, 0};
    
    kern_return_t kr;
    mach_msg_type_number_t count;
    host_cpu_load_info_data_t r_load;
    
    count = HOST_CPU_LOAD_INFO_COUNT;
    kr = host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, (int *)&r_load, &count);
    
    if (kr != KERN_SUCCESS) {
        //DebugLog(@"error fetching HOST_CPU_LOAD_INFO !!!");
    } else {
        sample.totalUserTime = r_load.cpu_ticks[CPU_STATE_USER] + r_load.cpu_ticks[CPU_STATE_NICE];
        sample.totalSystemTime = r_load.cpu_ticks[CPU_STATE_SYSTEM];
        sample.totalIdleTime = r_load.cpu_ticks[CPU_STATE_IDLE];
    }
    
    //DebugLog(@"got CPU sample [ user:%llu; sys:%llu; idle:%llu ]", sample.totalUserTime, sample.totalSystemTime, sample.totalIdleTime);
    
    return sample;
}

- (NetSample)getNetSample {
    /*
     NetSample: { timestamp, totalUploadBytes, totalDownloadBytes }
     */
    NetSample sample = {0, 0, 0};
    
    int mib[] = {
        CTL_NET,
        PF_ROUTE,
        0,
        0,
        NET_RT_IFLIST2,
        0
    };
    
    size_t len = 0;
    
    if (sysctl(mib, 6, NULL, &len, NULL, 0) >= 0) {
        char *buf = (char *)malloc(len);
        
        if (sysctl(mib, 6, buf, &len, NULL, 0) >= 0) {
            
            // read interface stats ...
            
            char *lim = buf + len;
            char *next = NULL;
            u_int64_t totalibytes = 0;
            u_int64_t totalobytes = 0;
            char name[32];
            
            for (next = buf; next < lim; ) {
                struct if_msghdr *ifm = (struct if_msghdr *)next;
                next += ifm->ifm_msglen;
                
                if (ifm->ifm_type == RTM_IFINFO2) {
                    struct if_msghdr2 *if2m = (struct if_msghdr2 *)ifm;
                    struct sockaddr_dl *sdl = (struct sockaddr_dl *)(if2m + 1);
                    
                    strncpy(name, sdl->sdl_data, sdl->sdl_nlen);
                    name[sdl->sdl_nlen] = 0;
                    
                    NSString *interface = [NSString stringWithUTF8String:name];
                    //DebugLog(@"interface (%u) name=%@", if2m->ifm_index, interface);
                    
                    // skip local interface (lo0)
                    if (![interface isEqualToString:@"lo0"]) {
                        totalibytes += if2m->ifm_data.ifi_ibytes;
                        totalobytes += if2m->ifm_data.ifi_obytes;
                    }
                }
            }
            
            sample.timestamp = [self timestamp];
            sample.totalUploadBytes = totalobytes;
            sample.totalDownloadBytes = totalibytes;
            
        } else {
            DebugLog(@"sysctl error !!!");
        }
        
        free(buf);
        
    } else {
        DebugLog(@"sysctl error !!!");
    }
    
    //DebugLog(@"got Net sample [ up:%llu; down=%llu ]", sample.totalUploadBytes, sample.totalDownloadBytes);
    
    return sample;
}

- (uint64_t)timestamp {
    
    // get timer units
    mach_timebase_info_data_t info;
    mach_timebase_info(&info);
    
    // get timer value
    uint64_t timestamp = mach_absolute_time();
    
    // convert to nanoseconds
    timestamp *= info.numer;
    timestamp /= info.denom;
    
    return timestamp;
}

- (NSString *)formatBytes:(double)bytes {
    NSString *result;
    
    if (bytes > (1024*1024*1024)) { // G
        result = [NSString stringWithFormat:@"%.1f GB/s", bytes/1024/1024/1024];
    } else if (bytes > (1024*1024)) { // M
        result = [NSString stringWithFormat:@"%.1f MB/s", bytes/1024/1024];
    } else if (bytes > 1024) { // K
        result = [NSString stringWithFormat:@"%.1f KB/s", bytes/1024];
    } else if (bytes > 0 ) {
        result = [NSString stringWithFormat:@"%.0f B/s", bytes];
    } else {
        result = @"0";
    }
    
    return result;
}

- (Meter *)meterForName:(NSString *)name {
	//DebugLog(@"looking for meter (%@) in self.meters=%@", name, self.meters);
	for (Meter *meter in self.meters) {
		if ([meter.name isEqualToString:name]) {
			return meter;
		}
	}
	return nil;
}


//---------- Expanded Content Stuff --------------------------------------------

- (NSString *)ipForInterface:(NSString *)interfaceName {
	NSString *address = @"n/a";
	
	struct ifaddrs *interfaces = NULL;
	struct ifaddrs *temp_addr = NULL;
	int success = 0;
	
	// get current interfaces (returns 0 on success)
	success = getifaddrs(&interfaces);
	
	if (success == 0) {
		// loop through linked list of interfaces
		temp_addr = interfaces;
		while (temp_addr != NULL) {
			if (temp_addr->ifa_addr->sa_family == AF_INET) {
				if ([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:interfaceName]) {
					address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
				}
			}
			temp_addr = temp_addr->ifa_next;
		}
	}
	freeifaddrs(interfaces); // free memory
	
	return address;
}

- (NSString *)wifiSSID {
	SBWiFiManager *wm = [objc_getClass("SBWiFiManager") sharedInstance];
    return ([wm currentNetworkName]) ?: @"n/a";
}

- (void)respringButtonTapped {
	pid_t pid;
	const char* args[] = { "sbreload", NULL };
	posix_spawn(&pid, "/usr/bin/sbreload", NULL, NULL, (char* const*)args, NULL);
}

- (void)restartButtonTapped {
	
	UIAlertController * alert = [UIAlertController
		alertControllerWithTitle:@"Reboot?"
		message:nil
		preferredStyle:UIAlertControllerStyleAlert];
	
    UIAlertAction* yesButton = [UIAlertAction
        actionWithTitle:@"Yes"
        style:UIAlertActionStyleDefault
        handler:^(UIAlertAction * action) {
			[[FBSSystemService sharedService] reboot];
        }];

    UIAlertAction* noButton = [UIAlertAction
       actionWithTitle:@"Cancel"
       style:UIAlertActionStyleDefault
       handler:^(UIAlertAction * action) {
           // no
       }];

    [alert addAction:yesButton];
    [alert addAction:noButton];

    [self presentViewController:alert animated:YES completion:nil];
}

- (void)restartUserspaceButtonTapped {
	UIAlertController * alert = [UIAlertController
		alertControllerWithTitle:@"Reboot Userspace?"
		message:nil
		preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction* yesButton = [UIAlertAction
        actionWithTitle:@"Yes"
        style:UIAlertActionStyleDefault
        handler:^(UIAlertAction * action) {
			pid_t pid;
			const char* args[] = { "launchctl", "reboot", "userspace", NULL };
			posix_spawn(&pid, "/bin/launchctl", NULL, NULL, (char* const*)args, NULL);
        }];

    UIAlertAction* noButton = [UIAlertAction
       actionWithTitle:@"Cancel"
       style:UIAlertActionStyleDefault
       handler:^(UIAlertAction * action) {
           // no
       }];

    [alert addAction:yesButton];
    [alert addAction:noButton];

    [self presentViewController:alert animated:YES completion:nil];
}

//------------------------------------------------------------------------------


- (void)dealloc {
    DebugLog(@"dealloc()");
    
	// make SURE the timer is dead.
	[_meterUpdateTimer invalidate];
	_meterUpdateTimer = nil;
}


@end
