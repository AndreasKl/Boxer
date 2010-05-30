/* 
 Boxer is copyright 2010 Alun Bestor and contributors.
 Boxer is released under the GNU General Public License 2.0. A full copy of this license can be
 found in this XCode project at Resources/English.lproj/GNU General Public License.txt, or read
 online at [http://www.gnu.org/licenses/gpl-2.0.txt].
 */


//BXCoalface defines C++-facing hooks which Boxer has injected into DOSBox functions to wrest
//control from DOSBox and pass it to Boxer at opportune moments.


#ifndef BOXER
#define BOXER

#if __cplusplus
extern "C" {
#endif
	
#import <SDL/SDL.h>
#import "config.h"
	
	//Called from sdlmain.cpp: perform various notifications and overrides.
	bool boxer_handleEventLoop();
	bool boxer_handleDOSBoxTitleChange(int cycles, int frameskip, bool paused);
	void boxer_applyConfigFiles();
	
	bool boxer_startFrame(Bit8u **frameBuffer, Bitu *pitch);
	void boxer_finishFrame(const uint16_t *dirtyBlocks);
	
	//Called from render.cpp: configures the DOSBox render state.
	void boxer_applyRenderingStrategy();
	
	//Called from messages.cpp: overrides DOSBox's translation system.
	const char * boxer_localizedStringForKey(char const * key);
	
	//Called from dos_keyboard_layout.cpp: provides the current OS X keyboard layout as a DOSBox layout code.
	const char * boxer_currentDOSKeyboardLayout();
	
	//Called from dos_programs.cpp: verifies that DOSBox is allowed to mount the specified folder.
	bool boxer_shouldMountPath(const char *filePath);
	
	//Called from shell.cpp: notifies Boxer when autoexec.bat is run.
	void boxer_autoexecDidStart();
	void boxer_autoexecDidFinish();
	
	//Called from shell.cpp: notifies Boxer when control returns to the DOS prompt.
	void boxer_didReturnToShell();
	
	//Called from shell_cmds.cpp: hooks into shell command processing.
	bool boxer_shouldRunShellCommand(char* cmd, char* args);
	
	//Called from shell_misc.cpp to allow Boxer to inject its own commands at the DOS command line.
	bool boxer_handleCommandInput(char *cmd, Bitu *cursorPosition, bool *executeImmediately);
	
	//Called from drive_cache.cpp: allows Boxer to hide OS X files that DOSBox shouldn't touch.
	bool boxer_shouldShowFileWithName(const char *name);
	
	//Called from drive_local.cpp: allows Boxer to restrict access to files that DOS programs shouldn't write to.
	bool boxer_shouldAllowWriteAccessToPath(const char *filePath, Bit8u driveIndex);
	
	//Called from dos_programs.cpp et al: informs Boxer of drive mount/unmount events.
	void boxer_driveDidMount(Bit8u driveIndex);
	void boxer_driveDidUnmount(Bit8u driveIndex);
	
	//Called from shell_misc.cpp to notify Boxer when a program or batchfile is executed.
	void boxer_willExecuteFileAtDOSPath(const char *dosPath, Bit8u driveIndex);
	void boxer_didExecuteFileAtDOSPath(const char *dosPath, Bit8u driveIndex);
	
	//Called from dosbox.cpp to short-circuit the emulation loop.
	bool boxer_handleRunLoop();
	
	void boxer_setMouseActive(bool mouseActive);
	void boxer_mouseMovedToPoint(float x, float y);
	
	SDLMod boxer_currentSDLModifiers();
#if __cplusplus
} //Extern C
#endif

#endif