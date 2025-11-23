				 
			 README.TXT

	    Release Notes for the Microsoft(R) Mouse
	   and Microsoft IntelliPoint version 1.10

	   (C) Copyright Microsoft Corporation, 1995

This document contains late-breaking information that supplements 
the Quick Reference Card and the IntelliPoint Online User's Guide.

-------------------------
How to View This Document
-------------------------
This document was formatted to be read in Windows(R) Notepad or the
MS-DOS(R) Editor.  To print the document in either application, 
choose Print from the File menu.

******************************************************************

CONTENTS

   I.   Important Safety Information

  II.   General Notes Covering Various Operating Systems
	1.  Do Not Install on a Network Drive
	2.  Using MS-DOS Disk Caching Software During Setup
	3.  Running IntelliPoint on a Computer with Multiple Operating 
	    Systems
	4.  Loading MOUSE.EXE into Upper Memory
	5.  Vanish Does Not Function in Spreadsheet Applications        
	6.  Changing IntelliPoint Settings in Windows vs. MS-DOS
	7.  Using IntelliPoint on a Laptop with an External Mouse
	8.  Detecting PS/2 Pointing Devices
	9.  Disabling SnapTo if You Use CorelDRAW

 III.   Notes For Windows 95 Users
	1.  Hiding the Taskbar When Using PointerWrap
	2.  Running IntelliPoint on a Computer with Multiple User Profiles
	3.  Some Mouse Tabs Are Part of the Operating System

  IV.   Notes for Windows NT(TM) Users
	1.  IntelliPoint Only Supports x86 Operating Systems
	2.  IntelliPoint Does Not Support Animation on the Desktop
	3.  Return to Previous Position Not Available in Windows NT

   V.   Notes for MS-DOS-Only Users
	Using Large and Medium Pointers
 
  VI.   Important Ergonomic Information

 VII.   Regulatory Information
	1.  United States Radio and TV Interference Regulations
	2.  Canadian Interference-Causing Equipment Regulations
 

====================================
Part I. Important Safety Information
====================================

Some studies suggest that long periods of repetitive motion coupled 
with an improper work environment and incorrect work habits may be 
linked to certain types of physical discomfort or injury.  These 
include carpal tunnel syndrome (CTS), tendinitis, and tenosynovitis.

It is important to follow all instructions contained in this section.  
Failure to do so may result in CTS, tendinitis or tenosynovitus.  
These instructions may not only help minimize your chances of 
experiencing one of these conditions, but will also help you to work 
more comfortably and effectively.  Ensuring that your chair, work 
surface, and placement of the mouse are in the correct positions is 
important.  In addition, you should take frequent breaks to avoid 
sitting in the same position for extended periods of time.


=========================================================
Part II: General Notes Covering Various Operating Systems
=========================================================

1.  Do Not Install on a Network Drive
 
    Installing IntelliPoint on a network drive is not supported.  
    Users with IntelliPoint version 1.00 installed on a network drive 
    will not be able to perform an upgrade to that drive.


2.  Using MS-DOS-based Disk Caching Software During Setup

    If you use MS-DOS-based disk cache software other than Microsoft 
    SMARTDrive, do not choose the Restart command after completing setup.
    Instead choose Exit, then exit Windows and restart your computer 
    manually.  Some MS-DOS-based disk caching programs use a write-behind 
    caching technique.  If the cache isn't flushed before restarting your 
    computer, disk errors could occur.

    Alternatively, you could temporarily disable your disk caching 
    software by 'REMing' it out in your AUTOEXEC.BAT file, then 
    re-enable it once you have installed IntelliPoint.


3.  Running IntelliPoint on a Computer with Multiple Operating Systems

    If you have installed Windows NT and Windows 95 on the same computer
    and IntelliPoint is installed on both operating systems, uninstalling 
    IntelliPoint from one operating system may remove files that are used
    by IntelliPoint on the other operating system.  If you encounter
    problems with IntelliPoint on the second operating system, reinstall
    it on that system.


4.  Loading MOUSE.EXE into Upper Memory
  
    The MS-DOS mouse driver is automatically loaded into upper memory, 
    if available. If you use the MS-DOS "loadhigh" command, your mouse 
    driver may be loaded into low memory.


5.  Vanish Does Not Function in Spreadsheet Applications

    The Vanish feature does not hide the pointer in spreadsheet 
    applications.


6.  Changing IntelliPoint Settings in Windows vs. MS-DOS

    When you change Set Buttons, Pointer Speed, Acceleration, and
    Orientation in a Windows version of IntelliPoint, the changes do not
    take effect in the MS-DOS version of IntelliPoint until you restart 
    your computer.  However, if you change these settings in the MS-DOS 
    version of IntelliPoint, the changes take effect in both versions 
    immediately.


7.  Using IntelliPoint on a Laptop with an External Mouse

    If you have an external mouse connected to your laptop computer, 
    the mouse driver will not work with the integrated pointing 
    device.  Disconnect the external mouse before using the mouse 
    driver with the integrated pointing device.

    To change the load order for the mouse driver so that the driver 
    will search for an external device first, do one of the following:

       If your system has an integrated Serial pointing device, add the
       following line to the [Mouse] section of the MSINPUT.INI file

	      EmbeddedType=Serial1

       If your system has an integrated PS/2 pointing device, add the
       following line to the [Mouse] section of the MSINPUT.INI file
  
	      EmbeddedType=PS2

    If no external device is found, the drivers will find the integrated 
    pointing device.
  
    NOTE: IntelliPoint supports only 100% Microsoft Mouse-compatible 
    pointing devices.
 

8.  Detecting PS/2 Pointing Devices

    Some hardware systems may have a hidden Extended BIOS for PS/2 devices 
    (some AST machines for instance).  To install the IntelliPoint drivers 
    correctly on these systems, add the following line to the [Mouse] 
    section of the MSINPUT.INI file:

	 FailIfNoExtendedBIOS=FALSE


9.  Disabling SnapTo if You Use CorelDRAW

    If you use the Zoom In feature in CorelDRAW, be sure to disable
    the SnapTo feature on the Activity tab.  Zoom In does not work 
    if SnapTo is enabled.


====================================
Part III. Notes for Windows 95 Users
====================================

1.  Hiding the Taskbar When Using the PointerWrap Feature

    When using PointerWrap in conjunction with the Windows 95 setting 
    to hide the Taskbar, it may be difficult to grab the Taskbar's 
    border.  If this happens, display the Taskbar by clicking the Start 
    button, pointing to Settings, and then clicking Taskbar.  Clear 
    the Auto hide check box.


2.  Running IntelliPoint on a Computer with Multiple User Profiles

    Uninstalling IntelliPoint under Windows 95 is not recommended 
    when user profiles are enabled on the system.  Uninstalling can 
    result in instability and invalid settings for other users who 
    logon to the computer.


3.  Some Mouse Tabs Are Part of the Operating System

    Under Windows 95, the Pointers and General tabs are a standard 
    part of the Windows 95 operating system and are not part of 
    IntelliPoint.  Only tabs with the Microsoft IntelliPoint logo 
    are installed by IntelliPoint.


===================================
Part IV.  Notes for Windows NT Users
===================================

1.  IntelliPoint Only Supports x86 Operating Systems

    This version of IntelliPoint only supports Intel-compatible x86 
    operating systems.  You cannot install IntelliPoint on another
    operating system, such as MIPS or Alpha.  However, you can use
    your mouse with those systems.    


2.  IntelliPoint Does Not Support Animation on the Desktop

    Under Windows NT, the animated special effects work in any window 
    and over any object.  However, animated special effects aren't 
    displayed when you click on the desktop.


3.  Return to Previous Position Not Available in Windows NT 

    In Windows 95 and Windows 3.1x, the SnapTo feature includes an option
    that enables you to return the pointer to its previous position when
    the dialog box closes.  This option is not available in Windows NT.


====================================
Part V. Notes for MS-DOS-Only Users
====================================

    Using Large and Medium Pointers
  
    When using a large- or medium-sized pointer, some MS-DOS-based
    applications may not redraw the pointer correctly, resulting
    in "mouse droppings".

    When using a large- or medium-sized pointer, the pointer might
    appear distorted in some applications.


=========================================
Part VI. Important Ergonomic Information
=========================================

NOTE:  If you have any version of Microsoft Windows installed, you 
       may find the Important Ergonomic Information contained
       in the IntelliPoint Online User's Guide easier to read. The 
       information below is a duplication of that information, and is 
       included here for users running only MS-DOS.

UNDERSTANDING ERGONOMICS

Ergonomics is the study of human performance and well-being in 
relation to the job, the equipment, the tools, and the environment.  
Ergonomics determines how interacting with computers, using specific 
work methods, and working in various settings affects people.

Personalizing your environment so that is is comfortable for your 
work situation promotes greater physical and mental well-being.  
Applying proper ergonomics principles will help make your office 
more comfortable.  In addition to improving the setup of your work 
area, it's important to consider your lifestyle.  Healthful food, 
exercise, and rest can help improve your health and comfort.  Use 
the tips listed below to work more comfortably.


SETTING UP YOUR WORKSPACE

Organize your work area so it is quiet and comfortable, with ample 
lighting and furniture suited to your body shape and size.

Tips
*  Locate your desk away from high-traffic areas.
*  Avoid a noisy setting. 
*  Keep the area under your desk clear of cables and other items so 
   you can sit comfortably without twisting.
*  Don't place your monitor in front of a window; rather, put it at 
   a right-angle to the window and use window shades to reduce glare.


ORGANIZING YOUR DESK AND SHELVES

Organize your desk space and nearby shelves to help you work more 
comfortably. Place books and other materials between knee and shoulder 
height on shelves.  Avoid reaching and twisting as you lift items from 
shelves.

Divide Your Desk into Three Zones:
*  Primary work zone -- the distance from elbow to hand.
   Use this zone to place the items you use most often within easy reach.
*  Secondary work zone -- within arm's reach.
   Use this zone to position those items that you use frequently, but 
   don't need all the time.
*  Reference zone -- outside arm's reach.
   Use this zone for your least-often used items.


ADJUSTING YOUR COMPUTER MONITOR FOR BETTER COMFORT

Use the proper lighting and adjust your computer screen and paperwork 
appropriately to help reduce eyestrain and fatigue.

Tips
*  Place monitor at eye level; lower if you wear bifocals.
*  Place screen 18 to 30 inches from your eyes.
*  Place your notes next to the screen at monitor height.
*  Tip the monitor down to avoid reflecting ceiling lights.  Keep 
   your screen clean.
*  Use high-contrast, natural screen colors.


USING INPUT DEVICES COMFORTABLY

There are things you can do while using the keyboard, mouse, or 
other input device to achieve greater comfort.

Tips
*  Use Shortcuts -- Learn as much as you can about your software 
   programs to help you minimize keystrokes and become more efficient 
   at using your computer.  Using a mouse or other input device can 
   provide a needed break from using the keyboard.
*  Use a Light Touch -- Press keys and hold the input device gently.
*  Avoid Unnecessary Reaching -- Keep the mouse or other input device 
   close to the keyboard to minimize reaching from the shoulder.  
   If you use the mouse or other input device more than the keyboard, 
   place it in front of you, with the keyboard a bit to one side.
*  Use Palm Rest When Not Typing -- Try to rest your palms and 
   wrists only when you aren't typing, but don't rest them on the 
   edge of a desk.  Move your keyboard forward enough so that you 
   can rest your palms on the palm rest.


COMPUTERS AND BODY FATIGUE

Some people who use computers experience discomfort such as back pain, 
stiff neck and shoulders, sore hands, or tired legs.  Much of this 
discomfort can be avoided, since these symptoms often arise from 
pushing the body beyond its natural limits.

Tips
*  Change Your Posture -- Changing position reduces muscle fatigue.  
   Maintain good back support and keep your wrists straight.  Avoid 
   awkward or twisted positions and frequent reaching.  Use a gentle 
   touch when typing or using the mouse.
*  Use Foot and Leg Support -- Be sure your feet are well supported, 
   either on the floor or on a footrest.  You may need a footrest if 
   you raise your chair to keep your wrists in a straight position.  
   Don't let the edge of your chair press into the backs of your knees.
*  Alternate Tasks -- Do a variety of tasks throughout the day, 
   alternating among several different types of tasks.  This gives your 
   body a chance to recover while you remain productive. 
*  Pause Regularly Throughout the Day -- To minimize fatigue, take 
   short rest breaks (30 seconds to two minutes) between tasks 
   throughout the day.  During your breaks, perform simple exercises 
   and deep breathing to help your body eliminate the effects of fatigue.


POSTURE FOR BACK AND SHOULDERS

Whether you work standing up or seated, try to minimize awkward 
postures, forceful exertions, and repetitive motion that can cause 
discomfort. 

When You Work Standing
*  Be sure to change posture frequently. 
*  Stand on an anti-fatigue mat to reduce fatigue. 

When You Work Sitting Down
*  Your chair should support your lower back.  Adjust chair height 
   so seat back contacts the most-curved part of your back. (Use a 
   pillow if needed.) 
*  Adjust armrests (if any) so you don't have to hunch your shoulders 
   or slouch down in your chair to use the armrests comfortably. 
*  Use a footrest, if needed, to reduce fatigue in your legs. 

  
Posture for Hands, Wrists, and Arms

Hold your hands, wrists, and arms in a neutral position while 
working to achieve greater comfort.

Tips
*  Be sure your upper arms drop naturally to your sides, so that 
   your shoulders are not shrugging.  Raise your chair or lower the 
   table as needed.
*  Place hands above the keyboard, with elbows at 90-degree angles.
*  Extend hands straight from the forearm, keeping your wrists straight.
*  Curl your fingers under slightly.

  
EXERCISES FOR YOUR BODY

During your rest pause, try these exercises to help you feel refreshed.  
Don't do any exercise that feels uncomfortable or causes straining.

Tips
*  Deep Breathing -- Relieves muscle tension.
*  Hand and Finger Massage -- Reduces cramping or stiffness and warms 
   your hands. 
*  Executive Stretch -- Exercises the entire upper body.  Clasp your 
   hands behind your head and gently stretch your elbows back, taking 
   in a deep breath as you stretch back. 
*  Shoulder Shrug -- Reduces tension or stiffness in the upper back 
   and neck.  Gently raise your shoulders up toward your ears and 
   then relax your shoulders downward. 
*  Foot Rotations -- Improves circulation to your legs and feet.  
   While seated, rotate each ankle three times clockwise, then 
   counter-clockwise. 
  

LIGHTING AND EYESTRAIN

Like other parts of the body, the eyes need to be relaxed from time 
to time.

Tips
*  Lighting -- When you work on a computer, the light level should 
   be dimmer than when you work with paper.  If you work with both, 
   choose relatively dim room lighting plus an adjustable reading 
   lamp that you can use for paperwork.
*  Glare -- Angle the reading lamp away from your eyes and away 
   from the monitor so that you can't see the unshaded light bulb 
   and so there is no glare on the monitor screen.
*  Reflections -- Remove any reflective materials--such as glass desk 
   pads and picture frames--from around your monitor to avoid 
   distracting reflections.  Also, try tilting your monitor downward, 
   or reposition it on your desk, to eliminate reflections.


EXERCISES FOR YOUR EYES

Take brief (30 seconds to two minutes) but frequent pauses while 
working at your computer to rest your eyes.  This pause gives your 
eyes a chance to recover from fatigue and help you feel refreshed.

Tips
*  Yawning and Blinking -- Keeps the eyes lubricated.
*  Changing Focus -- Relaxes the muscles of your eyes.  With your arm 
   stretched in front of you, look at your fingertips, then at a point 
   far away from you, then back to your fingertips.
*  Palming -- Helps to overcome eyestrain.  Support your head in your 
   hands, with your eyes covered, while you breathe deeply.


=================================
Part VII. Regulatory Information
=================================

1.  United States Radio and TV Interference Regulations

    This device complies with Part 15 of the U.S. Federal Communications
    Commission (FCC) Rules.  Operation is subject to the following 
    conditions: (1) this device may not cause harmful interference, and 
    (2) this device must accept any interference received, including 
    interference that may cause undesired operation.

    The Microsoft hardware device(s) which accompanies this software can 
    radiate radio frequency (RF) energy.  If not installed and used in 
    strict accordance with the instructions given in the printed  
    documentation, the device may cause harmful interference with radio
    and TV reception.  Any cable that is connected to the device must be
    a shielded cable that is properly grounded.

    Your Microsoft hardware device has been tested, and it complies with 
    the limits for a Class B computing device in accordance with the 
    specifications in Part 15 of the U.S. Federal Communications 
    Commission (FCC) rules.  These limits are designed to provide 
    reasonable protection against harmful RF interference in a residential 
    installation.  There is, however, no guarantee that RF interference 
    will not occur in a particular installation.

    To determine if your hardware device is causing interference, 
    disconnect the device from your computer.  If the interference stops, 
    it was probably caused by the device.  If the interference continues 
    after you disconnect the hardware device, turn the computer off and 
    then on again.  If the interference stopped when the computer was off, 
    check to see if one of the input/output (I/O) devices or one of the 
    computer's internal accessory boards is causing the problem.  
    Disconnect the I/O devices one at a time and see if the interference 
    stops.

    If your computer does cause interference, try the following measures 
    to correct it:

    *  Relocate the radio or TV antenna until the interference stops.
    *  Move the computer farther away from the radio or TV, or move it to 
       one side or the other of the radio or TV.
    *  Plug the computer into a different power outlet so that the 
       computer and radio or TV are on different circuits controlled by 
       different circuit breakers or fuses.
    *  If necessary, ask your computer dealer or an experienced radio-TV 
       technician for more suggestions.  You may find helpful information 
       in the booklet "The Interference Handbook" (1993), published by the 
       FCC.  The booklet is available from the U.S. Government Printing 
       Office, Washington, D.C. 20402.  The stock number is 004-000-00493-1.

    NOTE:  Any changes or modifications not expressly approved by Microsoft 
    could void the user's authority to operate this device.


2.  Canadian Interference-Causing Equipment Regulations

    This Class B digital apparatus meets all requirements of the Canadian 
    Interference-Causing Equipment Regulations.

    Cet appareil numérique de la classe B respecte toutes les exigences 
    du réglement sur le matériel brouilleur du Canada.

