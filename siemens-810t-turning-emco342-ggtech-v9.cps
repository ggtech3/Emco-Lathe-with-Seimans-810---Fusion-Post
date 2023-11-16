/**
  Copyright (C) 2012-2016 by Autodesk, Inc.
  All rights reserved.
 
  Siemens Lathe post processor configuration.
 
  $Revision: 41369 65a1f6cb57e3c7389dc895ea10958fc2f7947b0d $
  $Date: 2017-03-20 14:12:44 $
   
  FORKID {3505AD38-4010-4F6B-8F14-9CE36B9375F7}
*/
 
 /**
ggtech v1
-changed tool output
-changed program name output
-changed extension to NC
-changed g53HomePosition
-changed useRadius: true

ggtech v2 
-added pass through function
-changed var gotTailStock = true;
-changed var gotPartCatcher = true;
     
ggtech v3/v4
- fixing drilling cylce to currect sub rutine calls (L98)
- fixed chip breaking to be R11=3-3
- Fixed deep drilling to be R11=4-3  
- these are the only drilling options for this machine
- Threading works with only non canned cycle

ggtech V5
- Fixed drilling - both chip break and full retract
  -changed R26=" + zFormat.format(-Math.abs(DPR) )+
  -to      R26=" + zFormat.format(Math.abs(DPR) )+


visionforge V6
-  Fixed G33, all X values during G33 now have I values added (see note below)
  * added iPitchOutput() for I value addition
  * added "testX" variable to G33 function as a replacement for all values that previously had xOutput.format(_x) (in function onLinear)
  * changed writeBlock(gMotionModal.format(33), xOutput.format(_x), yOutput.format(_y), zOutput.format(_z), pitchOutput.format(1 / threadsPerInch));
        to writeBlock(gMotionModal.format(33), testX, yOutput.format(_y), zOutput.format(_z), pitchOutput.format(1 / threadsPerInch), (testX ? iPitchOutput.format(1 / threadsPerInch) : ""));
- Please note that this is a "band-aid" solution as it just copies the K values as the I value during threading, if the I value needs to be different than the K value this will not work.

ggtech V7
-the bellow has been reverted as it seems to have not been the issue for the drilling not stopping at right depth issue I encountered 
Fixed drilling - both chip break and full retract
  -changed R26=" + zFormat.format(-Math.abs(DPR) )+
  -to      R26=" + zFormat.format(Math.abs(DPR) )+

ggtech v8
Commented out the bellow g18 output- this was causing the control to error out. it doesnt need to be told the plane.
//writeBlock(gPlaneModal.format(18));// ggtech - removed G18 control doesnt like or need it

ggtech v9
Drilling was not going to correct depth, has been fixed by changing to cycle.bottom on r26
fixed both full retract and peck drilling
Note: these are the only cycles available for this machine
  ++writeln("(R26 = " + zFormat.format(cycle.bottom) +" Final drilling depth (absolute)");
	--writeln("(R26 = " + zFormat.format(-Math.abs(DPR)) +" Final drilling depth (absolute)");

  ++" R26=" + zFormat.format(cycle.bottom)+ 
	--" R26=" + zFormat.format(-Math.abs(DPR) )+ 


  */
 
description = "Emco 342 Siemens 810T - V9";
vendor = "Siemens";
vendorUrl = "http://www.siemens.com";
legal = "Copyright (C) 2012-2016 by Autodesk, Inc.";
certificationLevel = 2;
minimumRevision = 24000;
 
longDescription = "Emco 342 - CNC post for Siemens 810T.";
 
extension = "nc";
setCodePage("ascii");
 
capabilities = CAPABILITY_TURNING;
tolerance = spatial(0.002, MM);
 
minimumChordLength = spatial(0.01, MM);
minimumCircularRadius = spatial(0.01, MM);
maximumCircularRadius = spatial(1000, MM);
minimumCircularSweep = toRad(0.01);
maximumCircularSweep = toRad(179);
allowHelicalMoves = true;
allowedCircularPlanes = undefined; // allow any circular motion
 
 
 
// user-defined properties
properties = {
  writeMachine: false, // write machine
  showSequenceNumbers: false, // show sequence numbers
  sequenceNumberStart: 10, // first sequence number
  sequenceNumberIncrement: 1, // increment for sequence numbers
  optionalStop: false, // optional stop
  separateWordsWithSpace: true, // specifies that the words should be separated with a white space
  useRadius: true, // specifies that arcs should be output using the radius (R word) instead of the I, J, and K words.
  maximumSpindleSpeed: 100 * 60, // specifies the maximum spindle speed
  useParametricFeed: false, // specifies that feed should be output using R parameters
  showNotes: false, // specifies that operation notes should be output
  g53HomePositionX: 8, // home position for X-axis
  g53HomePositionZ: 16 // home position for Z-axis
};
 
 
var gFormat = createFormat({prefix:"G", decimals:1});
var mFormat = createFormat({prefix:"M", decimals:1});
var dFormat = createFormat({prefix:"D", decimals:0});
 
var spatialFormat = createFormat({decimals:(unit == MM ? 3 : 4)});
var xFormat = createFormat({decimals:(unit == MM ? 3 : 4), scale:2}); // diameter mode
var yFormat = createFormat({decimals:(unit == MM ? 3 : 4)});
var zFormat = createFormat({decimals:(unit == MM ? 3 : 4)});
var hFormat = createFormat({decimals:(unit == MM ? 3 : 4)});
var rFormat = createFormat({decimals:(unit == MM ? 3 : 4)}); // radius
var feedFormat = createFormat({decimals:(unit == MM ? 5 : 4)});
var pitchFormat = createFormat({decimals:(unit == MM ? 3 : 4)});
var toolFormat = createFormat({decimals:0});
var rpmFormat = createFormat({decimals:0});
var secFormat = createFormat({decimals:3}); // seconds - range 0.001-99999.999
var taperFormat = createFormat({decimals:1, scale:DEG});
 
var xOutput = createVariable({prefix:"X"}, xFormat);
var yOutput = createVariable({prefix:"Y"}, yFormat);
var zOutput = createVariable({prefix:"Z"}, zFormat);
var feedOutput = createVariable({prefix:"F"}, feedFormat);
var pitchOutput = createVariable({prefix:"K", force:true}, pitchFormat);
var sOutput = createVariable({prefix:"S", force:true}, rpmFormat);

var iPitchOutput = createVariable({prefix:"I", force:true}, pitchFormat); // visionforge - added iPitchOutput for hacky addition of i codes to all G33 lines with "x" in it
 
// circular output
var kOutput = createReferenceVariable({prefix:"K"}, spatialFormat);
var jOutput = createReferenceVariable({prefix:"J"}, spatialFormat);
var iOutput = createReferenceVariable({prefix:"I"}, spatialFormat); // no scaling
 
var gMotionModal = createModal({}, gFormat); // modal group 1 // G0-G3, ...
var gPlaneModal = createModal({onchange:function () {gMotionModal.reset();}}, gFormat); // modal group 2 // G17-19
var gAbsIncModal = createModal({}, gFormat); // modal group 3 // G90-91 // only for B and C mode
var gFeedModeModal = createModal({}, gFormat); // modal group 5 // G94-95
var gSpindleModeModal = createModal({}, gFormat); // modal group 5 // G96-97
var gUnitModal = createModal({}, gFormat); // modal group 6 // G70-71
var gCycleModal = createModal({}, gFormat); // modal group 9 // G81, ...
var gRetractModal = createModal({}, gFormat); // modal group 10 // G98-99
 
// fixed settings
var firstFeedParameter = 1;
var gotSecondarySpindle = false;
var gotDoorControl = false;
var gotTailStock = true;
var gotBarFeeder = false;
var gotPartCatcher = true;
 
var WARNING_WORK_OFFSET = 0;
 
// collected state
var sequenceNumber;
var currentWorkOffset;
var optionalSection = false;
var forceSpindleSpeed = false;
var activeMovements; // do not use by default
var currentFeedId;
 
 
 
/**
  Writes the specified block.
*/
function writeBlock() {
  if (properties.showSequenceNumbers) {
    if (optionalSection) {
      var text = formatWords(arguments);
      if (text) {
        writeWords("/", "N" + sequenceNumber, text);
      }
    } else {
      writeWords2("N" + sequenceNumber, arguments);
    }
    sequenceNumber += properties.sequenceNumberIncrement;
  } else {
    if (optionalSection) {
      writeWords2("/", arguments);
    } else {
      writeWords(arguments);
    }
  }
}
 
/**
  Writes the specified optional block.
*/
function writeOptionalBlock() {
  if (properties.showSequenceNumbers) {
    var words = formatWords(arguments);
    if (words) {
      writeWords("/", "N" + sequenceNumber, words);
      sequenceNumber += properties.sequenceNumberIncrement;
    }
  } else {
    writeWords2("/", arguments);
  }
}

function formatComment(text) {
  return "(" + String(text) + ")";
}
 
/**
  Output a comment.
*/

 function writeComment(text) {
 writeln(formatComment(text));
 }
 
function onOpen() {
  if (properties.useRadius) {
    maximumCircularSweep = toRad(90); // avoid potential center calculation errors for CNC
  }
 
  yOutput.disable();
  
  if (!properties.separateWordsWithSpace) {
    setWordSeparator("");
  }
 
  sequenceNumber = properties.sequenceNumberStart;
 
  // if (!((programName.length >= 2) && (isAlpha(programName[0]) || (programName[0] == "_")) && isAlpha(programName[1]))) {
  //   error(localize("Program name must begin with 2 letters."));
  // }


 if (programName) {
    var programId;
    try {
      programId = getAsInt(programName);
    } catch(e) {
      error(localize("Program name must be a number."));
      return;
    }

    if (properties.o8) {
      if (!((programId >= 1) && (programId <= 99999999))) {
        error(localize("Program number is out of range."));
        return;
    }

    } else {
      if (!((programId >= 0) && (programId <= 9999))) {
        error(localize("Program number is out of range."));
        return;
      }
    }

    oFormat = createFormat({width:(properties.o8 ? 8 : 4), zeropad:true, decimals:0});
    currentSubprogram = programId;
  } else {
    error(localize("Program name has not been specified."));
    return;
  }

  writeln("%MPF" + (programName));   

  if (programComment) {
    writeComment(programComment);
  }
 
// dump machine configuration
//  var vendor = machineConfiguration.getVendor();
//  var model = machineConfiguration.getModel();
//  var description = machineConfiguration.getDescription();
 
//  if (properties.writeMachine && (vendor || model || description)) {
//    writeComment(localize("Machine"));
//    if (vendor) {
//      writeComment("  " + localize("vendor") + ": " + vendor);
//    }
//    if (model) {
//      writeComment("  " + localize("model") + ": " + model);
//    }
//    if (description) {
//      writeComment("  " + localize("description") + ": "  + description);
//    }
//   }
 
  if ((getNumberOfSections() > 0) && (getSection(0).workOffset == 0)) {
    for (var i = 0; i < getNumberOfSections(); ++i) {
      if (getSection(i).workOffset > 0) {
        error(localize("Using multiple work offsets is not possible if the initial work offset is 0."));
        return;
      }
    }
  }
 
// absolute coordinates and feed per rev
  writeBlock(gAbsIncModal.format(90), gFormat.format(54));
 
//  switch (unit) {
//  case IN:
//    writeBlock(gUnitModal.format(70));
//    break;
//  case MM:
//    writeBlock(gUnitModal.format(71));
//    break;
//  }
 
  if (properties.maximumSpindleSpeed > 0) {
    writeBlock(gSpindleModeModal.format(92) + " " + sOutput.format(properties.maximumSpindleSpeed));
  }
 
  onCommand(COMMAND_START_CHIP_TRANSPORT);

}
 
function onComment(message) {
  writeComment(message);
}
 
/** Force output of X, Y, and Z. */
function forceXYZ() {
  xOutput.reset();
  yOutput.reset();
  zOutput.reset();
}
 
function forceFeed() {
  currentFeedId = undefined;
  feedOutput.reset();
}
 
/** Force output of X, Y, Z, and F on next output. */
function forceAny() {
  forceXYZ();
  forceFeed();
}
 
function FeedContext(id, description, feed) {
  this.id = id;
  this.description = description;
  this.feed = feed;
}
 
function getFeed(f) {
  if (activeMovements) {
    var feedContext = activeMovements[movement];
    if (feedContext != undefined) {
      if (!feedFormat.areDifferent(feedContext.feed, f)) {
        if (feedContext.id == currentFeedId) {
          return ""; // nothing has changed
        }
        forceFeed();
        currentFeedId = feedContext.id;
        return "F=R" + (firstFeedParameter + feedContext.id);
      }
    }
    currentFeedId = undefined; // force Q feed next time
  }
  return feedOutput.format(f); // use feed value
}
 
function initializeActiveFeeds() {
  activeMovements = new Array();
  var movements = currentSection.getMovements();
  var feedPerRev = currentSection.feedMode == FEED_PER_REVOLUTION;
   
  var id = 0;
  var activeFeeds = new Array();
  if (hasParameter("operation:tool_feedCutting")) {
    if (movements & ((1 << MOVEMENT_CUTTING) | (1 << MOVEMENT_LINK_TRANSITION) | (1 << MOVEMENT_EXTENDED))) {
      var feedContext = new FeedContext(id, localize("Cutting"), feedPerRev ? getParameter("operation:tool_feedCuttingRel") : getParameter("operation:tool_feedCutting"));
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_CUTTING] = feedContext;
      activeMovements[MOVEMENT_LINK_TRANSITION] = feedContext;
      activeMovements[MOVEMENT_EXTENDED] = feedContext;
    }
    ++id;
    if (movements & (1 << MOVEMENT_PREDRILL)) {
      feedContext = new FeedContext(id, localize("Predrilling"), feedPerRev ? getParameter("operation:tool_feedCuttingRel") : getParameter("operation:tool_feedCutting"));
      activeMovements[MOVEMENT_PREDRILL] = feedContext;
      activeFeeds.push(feedContext);
    }
    ++id;
  }
   
  if (hasParameter("operation:finishFeedrate")) {
    if (movements & (1 << MOVEMENT_FINISH_CUTTING)) {
      var finishFeedrateRel;
      if (hasParameter("operation:finishFeedrateRel")) {
        finishFeedrateRel = getParameter("operation:finishFeedrateRel");
      } else if (hasParameter("finishFeedratePerRevolution")) {
        finishFeedrateRel = getParameter("finishFeedratePerRevolution");
      }
      var feedContext = new FeedContext(id, localize("Finish"), feedPerRev ? finishFeedrateRel : getParameter("operation:finishFeedrate"));
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_FINISH_CUTTING] = feedContext;
    }
    ++id;
  } else if (hasParameter("operation:tool_feedCutting")) {
    if (movements & (1 << MOVEMENT_FINISH_CUTTING)) {
      var feedContext = new FeedContext(id, localize("Finish"), feedPerRev ? getParameter("operation:tool_feedCuttingRel") : getParameter("operation:tool_feedCutting"));
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_FINISH_CUTTING] = feedContext;
    }
    ++id;
  }
   
  if (hasParameter("operation:tool_feedEntry")) {
    if (movements & (1 << MOVEMENT_LEAD_IN)) {
      var feedContext = new FeedContext(id, localize("Entry"), feedPerRev ? getParameter("operation:tool_feedEntryRel") : getParameter("operation:tool_feedEntry"));
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_LEAD_IN] = feedContext;
    }
    ++id;
  }
 
  if (hasParameter("operation:tool_feedExit")) {
    if (movements & (1 << MOVEMENT_LEAD_OUT)) {
      var feedContext = new FeedContext(id, localize("Exit"), feedPerRev ? getParameter("operation:tool_feedExitRel") : getParameter("operation:tool_feedExit"));
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_LEAD_OUT] = feedContext;
    }
    ++id;
  }
 
  if (hasParameter("operation:noEngagementFeedrate")) {
    if (movements & (1 << MOVEMENT_LINK_DIRECT)) {
      var feedContext = new FeedContext(id, localize("Direct"), feedPerRev ? getParameter("operation:noEngagementFeedrateRel") : getParameter("operation:noEngagementFeedrate"));
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_LINK_DIRECT] = feedContext;
    }
    ++id;
  } else if (hasParameter("operation:tool_feedCutting") &&
             hasParameter("operation:tool_feedEntry") &&
             hasParameter("operation:tool_feedExit")) {
    if (movements & (1 << MOVEMENT_LINK_DIRECT)) {
      var feedContext = new FeedContext(
        id,
        localize("Direct"),
        Math.max(
          feedPerRev ? getParameter("operation:tool_feedCuttingRel") : getParameter("operation:tool_feedCutting"),
          feedPerRev ? getParameter("operation:tool_feedEntryRel") : getParameter("operation:tool_feedEntry"),
          feedPerRev ? getParameter("operation:tool_feedExitRel") : getParameter("operation:tool_feedExit")
        )
      );
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_LINK_DIRECT] = feedContext;
    }
    ++id;
  }
   
  if (hasParameter("operation:reducedFeedrate")) {
    if (movements & (1 << MOVEMENT_REDUCED)) {
      var feedContext = new FeedContext(id, localize("Reduced"), feedPerRev ? getParameter("operation:reducedFeedrateRel") : getParameter("operation:reducedFeedrate"));
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_REDUCED] = feedContext;
    }
    ++id;
  }
 
  if (hasParameter("operation:tool_feedRamp")) {
    if (movements & ((1 << MOVEMENT_RAMP) | (1 << MOVEMENT_RAMP_HELIX) | (1 << MOVEMENT_RAMP_PROFILE) | (1 << MOVEMENT_RAMP_ZIG_ZAG))) {
      var feedContext = new FeedContext(id, localize("Ramping"), feedPerRev ? getParameter("operation:tool_feedRampRel") : getParameter("operation:tool_feedRamp"));
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_RAMP] = feedContext;
      activeMovements[MOVEMENT_RAMP_HELIX] = feedContext;
      activeMovements[MOVEMENT_RAMP_PROFILE] = feedContext;
      activeMovements[MOVEMENT_RAMP_ZIG_ZAG] = feedContext;
    }
    ++id;
  }
  if (hasParameter("operation:tool_feedPlunge")) {
    if (movements & (1 << MOVEMENT_PLUNGE)) {
      var feedContext = new FeedContext(id, localize("Plunge"), feedPerRev ? getParameter("operation:tool_feedPlungeRel") : getParameter("operation:tool_feedPlunge"));
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_PLUNGE] = feedContext;
    }
    ++id;
  }
  if (true) { // high feed
    if (movements & (1 << MOVEMENT_HIGH_FEED)) {
      var feedContext = new FeedContext(id, localize("High Feed"), this.highFeedrate);
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_HIGH_FEED] = feedContext;
    }
    ++id;
  }
   
  for (var i = 0; i < activeFeeds.length; ++i) {
    var feedContext = activeFeeds[i];
    writeBlock("R" + (firstFeedParameter + feedContext.id) + "=" + feedFormat.format(feedContext.feed), formatComment(feedContext.description));
  }
}
 
function getSpindle() {
  if (getNumberOfSections() == 0) {
    return SPINDLE_PRIMARY;
  }
  if (getCurrentSectionId() < 0) {
    return getSection(getNumberOfSections() - 1).spindle == 0;
  }
  if (currentSection.getType() == TYPE_TURNING) {
    return currentSection.spindle;
  } else {
    if (isSameDirection(currentSection.workPlane.forward, new Vector(0, 0, 1))) {
      return SPINDLE_PRIMARY;
    } else if (isSameDirection(currentSection.workPlane.forward, new Vector(0, 0, -1))) {
      if (!gotSecondarySpindle) {
        error(localize("Secondary spindle is not available."));
      }
      return SPINDLE_SECONDARY;
    } else {
      return SPINDLE_PRIMARY;
    }
  }
}
 
function onSection() {
  if (currentSection.getType() != TYPE_TURNING) {
    if (!hasParameter("operation-strategy") || (getParameter("operation-strategy") != "drill")) {
      if (currentSection.getType() == TYPE_MILLING) {
        error(localize("Milling toolpath is not supported."));
      } else {
        error(localize("Non-turning toolpath is not supported."));
      }
      return;
    }
  }
 
  var forceToolAndRetract = optionalSection && !currentSection.isOptional();
  optionalSection = currentSection.isOptional();
 
  var turning = (currentSection.getType() == TYPE_TURNING);
   
  var insertToolCall = forceToolAndRetract || isFirstSection() ||
    currentSection.getForceToolChange && currentSection.getForceToolChange() ||
    (tool.number != getPreviousSection().getTool().number) ||
    (tool.compensationOffset != getPreviousSection().getTool().compensationOffset) ||
    (tool.diameterOffset != getPreviousSection().getTool().diameterOffset) ||
    (tool.lengthOffset != getPreviousSection().getTool().lengthOffset);

   
  var retracted = false; // specifies that the tool has been retracted to the safe plane
  var newSpindle = isFirstSection() ||
    (getPreviousSection().spindle != currentSection.spindle);
  var newWorkOffset = isFirstSection() ||
    (getPreviousSection().workOffset != currentSection.workOffset); // work offset changes
  if (insertToolCall || newSpindle || newWorkOffset) {
    // retract to safe plane
    retracted = true;
    writeBlock("D0");
    writeBlock(gAbsIncModal.format(90), gFormat.format(53), gMotionModal.format(0), "X" + hFormat.format(properties.g53HomePositionX) + gMotionModal.format(0), "Z" + zFormat.format(properties.g53HomePositionZ)); // retract
    // writeBlock(gAbsIncModal.format(90), gFormat.format(53), gMotionModal.format(0), "Z" + zFormat.format(properties.g53HomePositionZ)); // retract Z
    forceXYZ();
  }
 
  
  if (hasParameter("operation-comment")) {
    var comment = getParameter("operation-comment");
    if (comment) {
      writeComment(comment);
    }
  }
   
  if (properties.showNotes && hasParameter("notes")) {
    var notes = getParameter("notes");
    if (notes) {
      var lines = String(notes).split("\n");
      var r1 = new RegExp("^[\\s]+", "g");
      var r2 = new RegExp("[\\s]+$", "g");
      for (line in lines) {
        var comment = lines[line].replace(r1, "").replace(r2, "");
        if (comment) {
          writeComment(comment);
        }
      }
    }
  }
   
  if (insertToolCall) {
    retracted = true;
    onCommand(COMMAND_COOLANT_OFF);
   
    if (!isFirstSection() && properties.optionalStop) {
      onCommand(COMMAND_OPTIONAL_STOP);
    }
 
    if (tool.number > 8) {
      warning(localize("Geen posities meer in turret"));
    }
 
    var compensationOffset = tool.compensationOffset;
    if (compensationOffset > 99) {
      error(localize("Compensation offset is out of range."));
      return;
      }
    if (compensationOffset < 1) {
      var compensationOffset = tool.lengthOffset;
      }
    //writeBlock("T" + toolFormat.format(compensationOffset), dFormat.format(tool.number)); // even opletten tool en D- waarden omdraaien! GPM
	writeBlock("T" + toolFormat.format(tool.number), dFormat.format(compensationOffset)); // format should be T01 D01 -gg
  }

  // wcs
//  if (insertToolCall) { // force work offset when changing tool
//    currentWorkOffset = undefined;
//  }
//  var workOffset = currentSection.workOffset;
//  if (workOffset == 0) {
//    warningOnce(localize("Work offset has not been specified. Using G54 as WCS."), WARNING_WORK_OFFSET);
//    workOffset = 1;
//  }
//  if (workOffset > 0) {
//    if (workOffset > 4) {
//      error(localize("Work offset out of range."));
//      return;
//    } else {
//      if (workOffset != currentWorkOffset) {
//        writeBlock(gFormat.format(53 + workOffset)); // G54->G59
//        currentWorkOffset = workOffset;
//      }
//    }
//  }
 
  // set coolant after we have positioned at Z
  setCoolant(tool.coolant);
 
  forceAny();
  gMotionModal.reset();
 
//  gFeedModeModal.reset();
//  if (currentSection.feedMode == FEED_PER_REVOLUTION) {
//    writeBlock(gFeedModeModal.format(95));
//  } else {
//    writeBlock(gFeedModeModal.format(94));
//  }
 
  if (gotTailStock) {
    // writeBlock(mFormat.format(currentSection.tailstock ? 21 : 20));
  }
 
  // writeBlock(mFormat.format(clampPrimaryChuck ? x : x));
  // writeBlock(mFormat.format(clampSecondaryChuck ? x : x));
 
  var mSpindle = tool.clockwise ? 3 : 4;
  /*
  switch (currentSection.spindle) {
  case SPINDLE_PRIMARY:
    mSpindle = tool.clockwise ? 3 : 4;
    break;
  case SPINDLE_SECONDARY:
    break;
  }
  */
   
  gSpindleModeModal.reset();
  if (currentSection.getTool().getSpindleMode() == SPINDLE_CONSTANT_SURFACE_SPEED) {
    writeBlock(gSpindleModeModal.format(96), sOutput.format(tool.surfaceSpeed * ((unit == MM) ? 1/1000.0 : 1/12.0)), mFormat.format(mSpindle));
    var maximumSpindleSpeed = (tool.maximumSpindleSpeed > 0) ? Math.min(tool.maximumSpindleSpeed, properties.maximumSpindleSpeed) : properties.maximumSpindleSpeed;
    if (maximumSpindleSpeed > 0) {
      writeBlock(gSpindleModeModal.format(92) + " " + sOutput.format(maximumSpindleSpeed));
    }
  } else {
    writeBlock(gSpindleModeModal.format(95), sOutput.format(tool.spindleRPM), mFormat.format(mSpindle));
  }
   
  setRotation(currentSection.workPlane);
 
  var initialPosition = getFramePosition(currentSection.getInitialPosition());
  if (!retracted) {
    // TAG: need to retract along X or Z
    if (getCurrentPosition().z < initialPosition.z) {
      writeBlock(gMotionModal.format(0), zOutput.format(initialPosition.z));
    }
  }
 
  if (insertToolCall) {
    gMotionModal.reset();
     
    writeBlock(
      gAbsIncModal.format(90),
      gMotionModal.format(0), xOutput.format(initialPosition.x), yOutput.format(initialPosition.y), zOutput.format(initialPosition.z)
    );
 
    gMotionModal.reset();
  }
 
  if (properties.useParametricFeed &&
      hasParameter("operation-strategy") &&
      (getParameter("operation-strategy") != "drill") && // legacy
      !(currentSection.hasAnyCycle && currentSection.hasAnyCycle())) {
    if (!insertToolCall &&
        activeMovements &&
        (getCurrentSectionId() > 0) &&
        (getPreviousSection().getPatternId() == currentSection.getPatternId())) {     // use the current feeds
    } else {
      initializeActiveFeeds();
    }
  } else {
    activeMovements = undefined;
  }
 
  if (insertToolCall || retracted) {
    gPlaneModal.reset();
  }
}
 
function onDwell(seconds) {
  if (seconds > 99999.999) {
    warning(localize("Dwelling time is out of range."));
  }
  writeBlock(gFormat.format(4), "F" + secFormat.format(seconds));
}
 
var pendingRadiusCompensation = -1;
 
function onRadiusCompensation() {
  pendingRadiusCompensation = radiusCompensation;
}
 
var resetFeed = false;
 
function onRapid(_x, _y, _z) {
  var x = xOutput.format(_x);
  var y = yOutput.format(_y);
  var z = zOutput.format(_z);
  if (x || y || z) {
    if (pendingRadiusCompensation >= 0) {
      pendingRadiusCompensation = -1;
      switch (radiusCompensation) {
      case RADIUS_COMPENSATION_LEFT:
        writeBlock(gMotionModal.format(0), gFormat.format(41), x, y, z);
        break;
      case RADIUS_COMPENSATION_RIGHT:
        writeBlock(gMotionModal.format(0), gFormat.format(42), x, y, z);
        break;
      default:
        writeBlock(gMotionModal.format(0), gFormat.format(40), x, y, z);
      }
    } else {
      writeBlock(gMotionModal.format(0), x, y, z);
    }
    forceFeed();
  }
}
 
function onLinear(_x, _y, _z, feed) {
  if (isSpeedFeedSynchronizationActive()) {
    resetFeed = true;
    var threadPitch = getParameter("operation:threadPitch");
    var threadsPerInch = 1.0 / threadPitch; // per mm for metric
    var testX = xOutput.format(_x); // visionforge - created variable for xOutput to use in next line (if xOutPut.format() used more than once ever in this function, it "disappears" and does a bunch of whacky stuff, don't ask me to explain it)
    writeBlock(gMotionModal.format(33), testX, yOutput.format(_y), zOutput.format(_z), pitchOutput.format(1 / threadsPerInch), (testX ? iPitchOutput.format(1 / threadsPerInch) : "")); // visionforge - replaced "xOutput.format(_x)" with "testX" (see above) and adds hacky iPitchOutput.format() function for i code conditional on x existing in the same line
    return;
  }
  if (resetFeed) {
    resetFeed = false;
    forceFeed();
  }
  var x = xOutput.format(_x);
  var y = yOutput.format(_y);
  var z = zOutput.format(_z);
  var f = getFeed(feed);
  if (x || y || z) {
    if (pendingRadiusCompensation >= 0) {
      pendingRadiusCompensation = -1;
      //writeBlock(gPlaneModal.format(18));// ggtech - removed G18 control doesnt like or need it
      switch (radiusCompensation) {
      case RADIUS_COMPENSATION_LEFT:
        writeBlock(gMotionModal.format(isSpeedFeedSynchronizationActive() ? 32 : 1), gFormat.format(41), x, y, z, f);
        break;
      case RADIUS_COMPENSATION_RIGHT:
        writeBlock(gMotionModal.format(isSpeedFeedSynchronizationActive() ? 32 : 1), gFormat.format(42), x, y, z, f);
        break;
      default:
        writeBlock(gMotionModal.format(isSpeedFeedSynchronizationActive() ? 32 : 1), gFormat.format(40), x, y, z, f);
      }
    } else {
      writeBlock(gMotionModal.format(isSpeedFeedSynchronizationActive() ? 32 : 1), x, y, z, f);
    }
  } else if (f) {
    if (getNextRecord().isMotion()) { // try not to output feed without motion
      forceFeed(); // force feed on next line
    } else {
      writeBlock(gMotionModal.format(isSpeedFeedSynchronizationActive() ? 32 : 1), f);
    }
  }
}

function onCircular(clockwise, cx, cy, cz, x, y, z, feed) {
  if (isSpeedFeedSynchronizationActive()) {
    error(localize("Speed-feed synchronization is not supported for circular moves."));
    return;
  }
   
  if (pendingRadiusCompensation >= 0) {
    error(localize("Radius compensation cannot be activated/deactivated for a circular move."));
    return;
  }
 
  var start = getCurrentPosition();
 
  if (isFullCircle()) {
    if (properties.useRadius || isHelical()) { // radius mode does not support full arcs
      linearize(tolerance);
      return;
    }
    switch (getCircularPlane()) {
    case PLANE_XY:
      writeBlock(gAbsIncModal.format(90),  gMotionModal.format(clockwise ? 2 : 3), iOutput.format(cx - start.x, 0), jOutput.format(cy - start.y, 0), getFeed(feed));
      break;
    case PLANE_ZX:
      writeBlock(gAbsIncModal.format(90), gMotionModal.format(clockwise ? 2 : 3), iOutput.format(cx - start.x, 0), kOutput.format(cz - start.z, 0), getFeed(feed));
      break;
    case PLANE_YZ:
      writeBlock(gAbsIncModal.format(90), gMotionModal.format(clockwise ? 2 : 3), jOutput.format(cy - start.y, 0), kOutput.format(cz - start.z, 0), getFeed(feed));
      break;
    default:
      linearize(tolerance);
    }
  } else if (!properties.useRadius) {
    switch (getCircularPlane()) {
    case PLANE_XY:
      writeBlock(gAbsIncModal.format(90), gMotionModal.format(clockwise ? 2 : 3), xOutput.format(x), yOutput.format(y), zOutput.format(z), iOutput.format(cx - start.x, 0), jOutput.format(cy - start.y, 0), getFeed(feed));
      break;
    case PLANE_ZX:
      writeBlock(gAbsIncModal.format(90), gMotionModal.format(clockwise ? 2 : 3), xOutput.format(x), yOutput.format(y), zOutput.format(z), iOutput.format(cx - start.x, 0), kOutput.format(cz - start.z, 0), getFeed(feed));
      break;
    case PLANE_YZ:
      writeBlock(gAbsIncModal.format(90), gMotionModal.format(clockwise ? 2 : 3), xOutput.format(x), yOutput.format(y), zOutput.format(z), jOutput.format(cy - start.y, 0), kOutput.format(cz - start.z, 0), getFeed(feed));
      break;
    default:
      linearize(tolerance);
    }
  } else { // use radius mode
    var r = getCircularRadius();
    if (toDeg(getCircularSweep()) > (180 + 1e-9)) {
      r = -r; // allow up to <360 deg arcs
    }
    switch (getCircularPlane()) {
    case PLANE_XY:
      writeBlock(gMotionModal.format(clockwise ? 2 : 3), xOutput.format(x), yOutput.format(y), zOutput.format(z), "B" + rFormat.format(r), getFeed(feed));
      break;
    case PLANE_ZX:
      writeBlock(gMotionModal.format(clockwise ? 2 : 3), xOutput.format(x), yOutput.format(y), zOutput.format(z), "B" + rFormat.format(r), getFeed(feed));
      break;
    case PLANE_YZ:
      writeBlock(gMotionModal.format(clockwise ? 2 : 3), xOutput.format(x), yOutput.format(y), zOutput.format(z), "B" + rFormat.format(r), getFeed(feed));
      break;
    default:
      linearize(tolerance);
    }
  }
}
 
var expandCurrentCycle = false;
 
function onCycle() {
  expandCurrentCycle = false;
  var RTP = cycle.clearance; // return plane (absolute)
  var RFP = cycle.stock; // reference plane (absolute)
  var SDIS = cycle.retract - cycle.stock; // safety distance
  var DP = cycle.bottom; // depth (absolute)
  var DPR = RFP - cycle.bottom; // depth (relative to reference plane)
  var DTB = cycle.dwell;
  var SDIR = tool.clockwise ? 3 : 4; // direction of rotation: M3:3 and M4:4
  switch (cycleType) {
  case "drilling":
//expandCyclePoint(x, y, z);  
    break;
  case "deep-drilling":
 
 
    // add support for accumulated depth
	  var F = cycle.feedrate;
	  writeBlock(gMotionModal.format(94), feedOutput.format(F)); // GG added G94
    var FDEP = cycle.stock - cycle.incrementalDepth;
    var FDPR = cycle.incrementalDepth; // relative to reference plane (unsigned)
    var DAM = 0; // degression (unsigned)
    var DTS = 0; // dwell time at start
    var FRF = 1; // feedrate factor (unsigned)
    var VARI = 4-3; // full retract
    var _AXN = 3; // tool axis
    var _MDEP = cycle.incrementalDepth; // minimum drilling depth
    var _VRT = 0; // retraction distance
    var _DTD = (cycle.dwell != undefined) ? cycle.dwell : 0;
    var _DIS1 = 0; // limit distance
 if (properties.Cycle_Comments) {
	writeln("(L98 Deep hole drilling cycle with chip removal Full retract)");
	writeln("(R11 = " + zFormat.format(VARI) +" (0=With chip breaking, 1=With chip removal)");	
	writeln("(R22 = " + zFormat.format(RTP) +" Starting point in Z (absolute)");
	writeln("(R24 = " + zFormat.format(FDPR) +" Amount of degression (incremental) without sign)");
	writeln("(R25 = " + zFormat.format(FDPR) +" The first drilling depth (incremental) without sign)");
  writeln("(R26 = " + zFormat.format(cycle.bottom) +" Final drilling depth (absolute)");
	//writeln("(R26 = " + zFormat.format(-Math.abs(DPR)) +" Final drilling depth (absolute)");
	writeln("(R27 = " + zFormat.format(DTS) +" Dwell time at the starting point (for chip removal)");	
	writeln("(R28 = " + zFormat.format(DTB) +" Dwell time at the bottom of drilling hole (chip breaking)");
} 
    writeBlock(
		"R11=" + ("4-3")+ // zFormat.format(VARI)+ // GG had to hard code thiszFormat.format(VARI)+ 
		" R22=" + zFormat.format(RTP)+ 
		" R24=" + zFormat.format(FDPR)+ 
		" R25=" + zFormat.format(FDPR)+ 
    " R26=" + zFormat.format(cycle.bottom)+ 
		//" R26=" + zFormat.format(-Math.abs(DPR) )+ 
		" R27=" + zFormat.format(DTS)+ 
		" R28=" + zFormat.format(DTB)
    );
	writeBlock("L98 P1");
    break;
	
  case "chip-breaking":

  	var F = cycle.feedrate;
	  writeBlock(gMotionModal.format(94), feedOutput.format(F)); // GG added G94
    var FDEP = cycle.stock - cycle.incrementalDepth;
    var FDPR = cycle.incrementalDepth; // relative to reference plane (unsigned)
    var DAM = 0; // degression (unsigned)
    var DTS = 0; // dwell time at start
    var FRF = 1; // feedrate factor (unsigned)
    var VARI = 3-3; // chip breaking // GG Hard coded below
    var _MDEP = cycle.incrementalDepth; // minimum drilling depth
    var _VRT = 0; // retraction distance
    var _DTD = (cycle.dwell != undefined) ? cycle.dwell : 0;
    var _DIS1 = 0; // limit distance
	
   if (properties.Cycle_Comments) {
	writeln("(L98 Deep hole drilling cycle with chip breaking (chip breaking)");
   	writeln("(The drill bit is retracted by 1 mm for chip breaking each time)");
	writeln("(R11 = " + zFormat.format(VARI) +" (3-3=With chip breaking, 4-3=With chip removal)");	
	writeln("(R22 = " + zFormat.format(RTP) +" Starting point in Z (absolute)");
	writeln("(R24 = " + zFormat.format(FDPR) +" Amount of degression (incremental) without sign)");
	writeln("(R25 = " + zFormat.format(FDPR) +" The first drilling depth (incremental) without sign)");
	writeln("(R26 = " + zFormat.format(cycle.bottom) +" Final drilling depth (absolute)");
  //writeln("(R26 = " + zFormat.format(-Math.abs(DPR)) +" Final drilling depth (absolute)");
	writeln("(R27 = " + zFormat.format(DTS) +" Dwell time at the starting point (for chip removal)");	
	writeln("(R28 = " + zFormat.format(DTB) +" Dwell time at the bottom of drilling hole (chip breaking)"); 	  
  } 
    writeBlock(
		"R11=" + ("3-3")+ // zFormat.format(VARI)+ // GG had to hard code this
		" R22=" + zFormat.format(RTP)+ 
		" R24=" + zFormat.format(FDPR)+ 
		" R25=" + zFormat.format(FDPR)+ 
		" R26=" + zFormat.format(cycle.bottom)+ 
    //" R26=" + zFormat.format(-Math.abs(DPR) )+ 
		" R27=" + zFormat.format(DTS)+ 
		" R28=" + zFormat.format(DTB)
    );
	writeBlock("L98 P1");
    break;

		  
  default:
    expandCurrentCycle = true;
  }
  if (!expandCurrentCycle) {
    xOutput.reset();
    yOutput.reset();
  }
}

function onCyclePoint(x, y, z) {
	if (isFirstCyclePoint()) {
	//expandCyclePoint(x, y, z);
}
	 if (isLastCyclePoint()) {
}
switch (cycleType) {
    case "thread-turning":
    
    if (!isLastCyclePoint())
        
        return;
 
    var backFromFront = hasParameter("operation:applyStockOffsetBackFromFront") && getParameter("operation:applyStockOffsetBackFromFront") === 1;
    var pos = backFromFront ? currentSection.getFinalPosition() : currentSection.getInitialPosition();
    var ThreadFinishPointZ = backFromFront ? pos.z : z;
    var external = false;
    
    
    var driveLine = cycle.retract;
    //writeln("driveLine " + cycle.retract);
    var threadCrest;
     if (getParameter( "operation:turningMode" )== "outer") {
         //writeln("operation:turningMode " + getParameter( "operation:turningMode" ));
     ThreadDepth = -getParameter("operation:threadDepth");
     threadCrest = getParameter("operation:outerRadius_value");
     }
     if (getParameter( "operation:turningMode" )== "inner") {
         //writeln("operation:turningMode " + getParameter( "operation:turningMode" ));
         ThreadDepth = getParameter("operation:threadDepth");
         threadCrest = getParameter("operation:innerRadius_value");
     }	
 
    ThreadStartPointX = x - ThreadDepth;
    var variabel = 0.458332061767578
    var Adjustment1 = -0.229166030883789 * +getParameter("operation:threadPitch");
    var Adjustment = Adjustment1 + variabel;
    ThreadFinishPointZ = ThreadFinishPointZ - Adjustment;
    ThreadStartPointZ = ThreadFinishPointZ + -cycle.incrementalZ;
 
     if (properties.Cycle_Comments) {
     writeln("(R20 = " + getParameter("operation:threadPitch") +" Thread Pitch)");
     writeln("(R21 = " + xFormat.format(ThreadStartPointX) +" Start point of the thread in X aka major diameter of thread in DIAMETER)");
     writeln("(R22 = " + zFormat.format(ThreadStartPointZ - getParameter("operation:stockOffsetFront")) +" Start point of the thread in Z)");
     writeln("(R23 = " + getParameter("operation:nullPass") +" Number of idle passes aka finishing passes)");
     writeln("(R24 = " + zFormat.format(ThreadDepth) +" Thread depth major diameter minus minor dia divided by 2 (positive value = inside thread, negative value = outside thread))");
     writeln("(R25 = " + properties.G76finishingPassDepthDesire +" Finishing increment finishing cut depth)");
     writeln("(R26 = " + getParameter("operation:stockOffsetFront") +" Approach Path)");
     writeln("(R27 = " + getParameter("operation:stockOffsetBack") +" Run-Out Path)");
     writeln("(R28 = " + getParameter("operation:numberOfStepdowns") +" Number of roughing cuts you define the number and the conrol calculates the depths)");
     writeln("(R29 = " + getParameter("operation:infeedAngle") +" Infeed Angle)");
     writeln("(R31 = " + xFormat.format(ThreadStartPointX) +" End point of the thread in X normally the same as R21 (absolute))");
     writeln("(R32 = " + zFormat.format(ThreadFinishPointZ + getParameter("operation:stockOffsetBack")) +" End point of the thread in z (absolute))");
     //writeln("");
     //writeln("(Select face in geometry tab and selection in the clearance tab.)");
 }
    
    writeBlock(
        "R20=" + getParameter("operation:threadPitch") + //Pitch
        " R21=" + xFormat.format(ThreadStartPointX) + //Start point of the thread in X
        " R22=" + zFormat.format(ThreadStartPointZ - getParameter("operation:stockOffsetFront")) + //Start point of the thread in Z
        " R23=" + getParameter("operation:nullPass") + //Number of idle passes
        " R24=" + zFormat.format(ThreadDepth) + //Thread depth (positive value = inside thread, negative value = outside thread)
        " R25=" + properties.G76finishingPassDepthDesire + //Finishing increment
        " R26=" + getParameter("operation:stockOffsetFront") + //Approach Path
        " R27=" + getParameter("operation:stockOffsetBack") + //Run-Out Path
        " R28=" + getParameter("operation:numberOfStepdowns") + //Number of roughing cuts
        " R29=" + getParameter("operation:infeedAngle") + //Infeed Angle
        " R31=" + xFormat.format(ThreadStartPointX) + //End point of the thread in X (absolute)
        " R32=" + zFormat.format(ThreadFinishPointZ + getParameter("operation:stockOffsetBack")) //End point of the thread in z (absolute) NOT SURE IF THIS IS RIGHT or it should be jsut threadfinishpoingz CJT
    );
    writeBlock("L97 P1");
 


   return;
   }

  if (isFirstCyclePoint()) {
    repositionToCycleClearance(cycle, x, y, z);
    
    // return to initial Z which is clearance plane and set absolute mode
    var F = cycle.feedrate;
    var P = (cycle.dwell == 0) ? 0 : clamp(1, cycle.dwell * 1000, 99999999); // in milliseconds
    switch (cycleType) {
    case "drilling":
		expandCyclePoint(x, y, z);
		return;
    case "counter-boring":
    case "chip-breaking":
    case "deep-drilling":
    case "tapping":
    case "left-tapping":
    case "right-tapping":
    case "tapping-with-chip-breaking":
    case "left-tapping-with-chip-breaking":
    case "right-tapping-with-chip-breaking":
    case "fine-boring":
    case "reaming":
    case "stop-boring":
    case "boring":
    }
  } else {
    if (cycleExpanded) {
      expandCyclePoint(x, y, z);
    } else {
      writeBlock(yOutput.format(y));
    }
  }
}
 
function onCyclePoint(x, y, z) {
  if (!expandCurrentCycle) {
    var _x = xOutput.format(x);
    var _y = yOutput.format(y);
    /*zOutput.format(z)*/
    if (_x || _y) {
      writeBlock(_x, _y);
    }
  } else {
    expandCyclePoint(x, y, z);
  }
}
 
function onCycleEnd() {
  if (!expandCurrentCycle) {
    // end modal cycle
  }
  zOutput.reset();
}
 
var currentCoolantMode = COOLANT_OFF;
 
function setCoolant(coolant) {
  if (coolant == currentCoolantMode) {
    return; // coolant is already active
  }
 
  var m = undefined;
  if (coolant == COOLANT_OFF) {
    writeBlock(mFormat.format(9));
    currentCoolantMode = COOLANT_OFF;
    return;
  }
 
 
  switch (coolant) {
  case 1: //coolant flood
    m = 8;
    m1 = 0;
    break;
  case 3: // coolant through tool
    m = 7;
    m1 = 0;
    break;
  case 8: // coolant flood and through tool
    m = 8;
    m1 = 7;	
    break;
  default:
    onUnsupportedCoolant(coolant);
    m = 9;
  }
   
  if (m) {
    writeBlock(mFormat.format(m));
    currentCoolantMode = coolant;
  }
  if (m1) {
    writeBlock(mFormat.format(m1));
    currentCoolantMode = coolant;
  }
}
 
function onCommand(command) {
  switch (command) {
  case COMMAND_COOLANT_OFF:
    setCoolant(COOLANT_OFF);
    return;
  case COMMAND_COOLANT_ON:
    setCoolant(COOLANT_FLOOD);
    return;
  case COMMAND_LOCK_MULTI_AXIS:
    return;
  case COMMAND_UNLOCK_MULTI_AXIS:
    return;
  case COMMAND_START_CHIP_TRANSPORT:
    return;
  case COMMAND_STOP_CHIP_TRANSPORT:
    return;
  case COMMAND_BREAK_CONTROL:
    return;
  case COMMAND_TOOL_MEASURE:
    return;
  case COMMAND_ACTIVATE_SPEED_FEED_SYNCHRONIZATION:
    return;
  case COMMAND_DEACTIVATE_SPEED_FEED_SYNCHRONIZATION:
    return;
 
  case COMMAND_STOP:
    writeBlock(mFormat.format(0));
    forceSpindleSpeed = true;
    return;
  case COMMAND_OPTIONAL_STOP:
    writeBlock(mFormat.format(1));
    break;
  case COMMAND_END:
    writeBlock(mFormat.format(2));
    break;
  case COMMAND_SPINDLE_CLOCKWISE:
    switch (currentSection.spindle) {
    case SPINDLE_PRIMARY:
      writeBlock(mFormat.format(3));
      break;
    case SPINDLE_SECONDARY:
      break;
    }
    // writeBlock("M2=3"); // live spindle
    break;
  case COMMAND_SPINDLE_COUNTERCLOCKWISE:
    switch (currentSection.spindle) {
    case SPINDLE_PRIMARY:
      writeBlock(mFormat.format(4));
      break;
    case SPINDLE_SECONDARY:
      break;
    }
    // writeBlock("M2=4"); // live spindle
    break;
  case COMMAND_START_SPINDLE:
    onCommand(tool.clockwise ? COMMAND_SPINDLE_CLOCKWISE : COMMAND_SPINDLE_COUNTERCLOCKWISE);
    return;
  case COMMAND_STOP_SPINDLE:
    switch (currentSection.spindle) {
    case SPINDLE_PRIMARY:
      writeBlock(mFormat.format(5));
      break;
    case SPINDLE_SECONDARY:
      break;
    }
    // writeBlock("M2=5"); // live spindle
    break;
  //case COMMAND_ORIENTATE_SPINDLE:
  //case COMMAND_CLAMP: // TAG: add support for clamping
  //case COMMAND_UNCLAMP: // TAG: add support for clamping
  default:
    onUnsupportedCommand(command);
  }
}
  /**
  Writes pass through - Add by GG
*/
function onPassThrough(text) {
  var commands = String(text).split(",");
  for (text in commands) {
    writeBlock(commands[text]);
  }
}
function onSectionEnd() {
  forceAny();
}
 
function onClose() {
  optionalSection = false;
 
  onCommand(COMMAND_COOLANT_OFF);
 
// we might want to retract in Z before X
// writeBlock(gAbsIncModal.format(90), gFormat.format(53), gMotionModal.format(0), "Z" + zFormat.format(0)); // retract
 
//  forceXYZ();
//  if (!machineConfiguration.hasHomePositionX() && !machineConfiguration.hasHomePositionY()) {
//    writeBlock(gAbsIncModal.format(90), gFormat.format(53), gMotionModal.format(0), "X" + hFormat.format(properties.g53HomePositionX)), conditional(yOutput.isEnabled(), "Y" + yFormat.format(0)); + gAbsIncModal.format(90), gFormat.format(53), gMotionModal.format(0), "Z" + hFormat.format(properties.g53HomePositionZ); // return to home
//  } else {
//    var homeX;
//    if (machineConfiguration.hasHomePositionX()) {
//      homeX = xOutput.format(machineConfiguration.getHomePositionX());
//    }
//    var homeY;
//    if (yOutput.isEnabled() && machineConfiguration.hasHomePositionY()) {
//      homeY = yOutput.format(machineConfiguration.getHomePositionY());
//    }
//    var homeZ;
//    if (machineConfiguration.hasHomePositionZ()) {
//      homeZ = zOutput.format(machineConfiguration.getHomePositionZ());
//    }
//    writeBlock(gAbsIncModal.format(90), gFormat.format(53), gMotionModal.format(0), homeX, homeZ, zOutput.format(machineConfiguration.getRetractPlane()));
//   }

      writeBlock("D0");
      writeBlock(gAbsIncModal.format(90), gFormat.format(53), gMotionModal.format(0), "X" + hFormat.format(properties.g53HomePositionX), gMotionModal.format(0), "Z" + zFormat.format(properties.g53HomePositionZ)); // return to home

 
  onImpliedCommand(COMMAND_END);
  onImpliedCommand(COMMAND_STOP_SPINDLE);
  writeBlock(mFormat.format(30)); // stop program, spindle stop, coolant off
}