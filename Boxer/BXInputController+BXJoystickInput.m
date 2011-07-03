/* 
 Boxer is copyright 2011 Alun Bestor and contributors.
 Boxer is released under the GNU General Public License 2.0. A full copy of this license can be
 found in this XCode project at Resources/English.lproj/BoxerHelp/pages/legalese.html, or read
 online at [http://www.gnu.org/licenses/gpl-2.0.txt].
 */


#import "BXInputControllerPrivate.h"
#import "BXAppController.h"
#import "BXJoystickController.h"
#import "BXHIDControllerProfile.h"


@implementation BXInputController (BXJoystickInput)
//Synthesized in BXInputController.m, but compiler overlooks that and throws up warnings otherwise
@dynamic availableJoystickTypes;

#pragma mark -
#pragma mark Setting and getting joystick configuration

+ (NSSet *) keyPathsForValuesAffectingStrictGameportTiming
{
	return [NSSet setWithObject: @"representedObject.emulator.gameportTimingMode"];
}

+ (NSSet *) keyPathsForValuesAffectingJoystickType
{
	return [NSSet setWithObject: @"representedObject.emulator.joystick"];
}

+ (NSSet *) keyPathsForValuesAffectingPreferredJoystickType
{
	return [NSSet setWithObjects: @"availableJoystickTypes", @"representedObject.gameSettings.preferredJoystickType", nil];
}

+ (NSSet *) keyPathsForValuesAffectingSelectedJoystickTypeIndexes
{
	return [NSSet setWithObjects: @"preferredJoystickType", @"availableJoystickTypes", nil];
}

- (BOOL) strictGameportTiming
{
	BXEmulator *emulator = [[self representedObject] emulator];
	return [emulator gameportTimingMode] == BXGameportTimingClockBased;
}

- (void) setStrictGameportTiming: (BOOL)flag
{
	BXSession *session = [self representedObject];
	BXEmulator *emulator = [session emulator];
	
	BXGameportTimingMode mode = (flag) ? BXGameportTimingClockBased : BXGameportTimingPollBased;
	if ([emulator gameportTimingMode] != flag)
	{
		[emulator setGameportTimingMode: mode];
		
		//Preserve changes in the per-game settings
		[[session gameSettings] setObject: [NSNumber numberWithBool: flag] forKey: @"strictGameportTiming"];
	}
}

- (NSIndexSet *) selectedJoystickTypeIndexes
{
	NSUInteger typeIndex = NSNotFound;
	Class currentType = [self preferredJoystickType];
	
	if (currentType)
	{
		typeIndex = [[self availableJoystickTypes] indexOfObject: currentType];
	}
	
	if (typeIndex != NSNotFound) return [NSIndexSet indexSetWithIndex: typeIndex];
	else return [NSIndexSet indexSet];
}

- (void) setSelectedJoystickTypeIndexes: (NSIndexSet *)types
{
	NSUInteger typeIndex = [types firstIndex];
	NSArray *availableTypes = [self availableJoystickTypes];
	if (typeIndex != NSNotFound && typeIndex < [availableTypes count])
	{
		Class selectedType = [availableTypes objectAtIndex: typeIndex];
		if (selectedType)
		{
			[self setPreferredJoystickType: selectedType];
		}
	}
}

- (Class) preferredJoystickType
{
	BXSession *session = [self representedObject];
	NSArray *availableTypes = [self availableJoystickTypes];
	Class defaultJoystickType = [availableTypes count] ? [availableTypes objectAtIndex: 0] : nil;
	
	NSString *className	= [[session gameSettings] objectForKey: @"preferredJoystickType"];
	
	//If no setting exists, then fall back on the default joystick type
	if (!className) return defaultJoystickType;
	
	//If the setting was an empty string, this indicates no joystick support
	else if (![className length]) return nil;
	
	//Otherwise return the specified joystick type class: or the default joystick type, if no such class exists
	else
	{
		Class joystickType = NSClassFromString(className);
		if ([joystickType conformsToProtocol: @protocol(BXEmulatedJoystick)]) return joystickType;
		else return defaultJoystickType;
	}
}

- (void) setPreferredJoystickType: (Class)joystickType
{
	if (joystickType != [self preferredJoystickType])
	{
		//Persist the new joystick type into the per-game settings
		NSString *className;
		if (joystickType != nil)
		{
			className = NSStringFromClass(joystickType);
		}
		else
		{
			className = @"";
		}
		NSMutableDictionary *gameSettings = [[self representedObject] gameSettings];
		[gameSettings setObject: className forKey: @"preferredJoystickType"];
		
		//Reinitialize the joysticks to use the newly-selected joystick type
		[self _syncJoystickType];
	}
}


- (BOOL) joystickControllersAvailable
{
    return [[[[NSApp delegate] joystickController] joystickDevices] count] > 0;
}

- (BOOL) controllersAvailable
{
	return [self joystickControllersAvailable] || [self joypadControllersAvailable];
}

- (void) _syncAvailableJoystickTypes
{
	//Filter joystick options based on the level of game support for them
	BXSession *session = [self representedObject];
	BXJoystickSupportLevel supportLevel = [[session emulator] joystickSupport];
	
	NSArray *types;
	if (supportLevel == BXJoystickSupportFull)
	{
		types = [NSArray arrayWithObjects:
			[BX4AxisJoystick class],
			[BXThrustmasterFCS class],
			[BXCHFlightStickPro class],
			[BX2AxisWheel class],
			nil];
	}
	else if (supportLevel == BXJoystickSupportSimple)
	{
		types = [NSArray arrayWithObjects:
			[BX2AxisJoystick class],
			[BX2AxisWheel class],
			nil];
	}
	else types = [NSArray array];
	
	[self setAvailableJoystickTypes: types];
}

- (void) _syncJoystickType
{
	BXEmulator *emulator = [[self representedObject] emulator];
	BXJoystickSupportLevel support = [emulator joystickSupport];
	
	Class preferredJoystickClass = [self preferredJoystickType];
	
	//If the current game doesn't support joysticks, or the user has chosen
	//to disable joystick support, or there are no real controllers connected,
    //then remove the emulated joystick and don't continue further.
	if (support == BXNoJoystickSupport || !preferredJoystickClass || ![self controllersAvailable])
	{
		[emulator detachJoystick];
	}
	else
    {
		Class joystickClass;
		
		//TODO: ask BXEmulator to validate the specified class,
        //and fall back on the 2-axis joystick otherwise
		if (support == BXJoystickSupportFull)
		{
			joystickClass = preferredJoystickClass;
		}
		else
        {
            joystickClass = [BX2AxisJoystick class];
        }
		
		if (![[emulator joystick] isMemberOfClass: joystickClass])
			[emulator attachJoystickOfType: joystickClass];
	}
}

- (void) _syncControllerProfiles
{
    id <BXEmulatedJoystick> joystick = [[[self representedObject] emulator] joystick];
    
    [controllerProfiles removeAllObjects];
    if (joystick)
    {
        NSArray *controllers = [[[NSApp delegate] joystickController] joystickDevices];
        for (DDHidJoystick *controller in controllers)
        {
            BXHIDControllerProfile *profile = [BXHIDControllerProfile profileForHIDController: controller
                                                                           toEmulatedJoystick: joystick];
            
            NSNumber *locationID = [NSNumber numberWithLong: [controller locationId]];
            [controllerProfiles setObject: profile forKey: locationID];
        }
    }
}



#pragma mark -
#pragma mark Handling HID events

//Send the event on to the controller profile for the specified device
- (void) dispatchHIDEvent: (BXHIDEvent *)event
{
	DDHidDevice *device = [event device];
	NSNumber *locationID = [NSNumber numberWithLong: [device locationId]];
	
	BXHIDControllerProfile *profile = [controllerProfiles objectForKey: locationID];
	[profile dispatchHIDEvent: event];
}

@end
