int arrSize = 20;
int barWidth = 40, barPadding = 10, partPadding = 40;
int maxElm = 100;
float heightFactor = 4;
int sortedCount = 0;
int opInterval = 500, actionDur = 300;

class Element {
  int value;
  float x, y;
  color colour;
}
Element[] elm = new Element[arrSize];
float maxY = maxElm * heightFactor + barPadding;
color sortedColour = color(192, 192, 144), unsortedColour = color(144, 192, 255),
      scannerColour = color(48, 255, 48), unsortedMinColour = color(255, 64, 64);

// The order part
int[] unsorted = new int[arrSize];
int unsortedCount = arrSize;
int unsortedItr, unsortedMinIdx;

// The animation part
int lastMillis, lastOpMillis;
class MoveAction {
  boolean isRunning;
  float x1, y1, x2, y2;
  int totTime, elapsedTime;
  float step(int dt) { return (float)(this.elapsedTime += dt) / (float)this.totTime; }
}
MoveAction[] mvact = new MoveAction[arrSize];
class TintAction {
  boolean isRunning;
  float r1, g1, b1, r2, g2, b2;
  int totTime, elapsedTime;
  float step(int dt) { return (float)(this.elapsedTime += dt) / (float)this.totTime; }
}
TintAction[] tnact = new TintAction[arrSize];
void activateMove(int idx, float x2, float y2, int dur)
{
  mvact[idx].isRunning = true;
  mvact[idx].x1 = elm[idx].x; mvact[idx].y1 = elm[idx].y;
  mvact[idx].x2 = x2; mvact[idx].y2 = y2;
  mvact[idx].totTime = dur;
  mvact[idx].elapsedTime = 0;
}
void activateTint(int idx, color c2, int dur)
{
  tnact[idx].isRunning = true;
  tnact[idx].r1 = red(elm[idx].colour);
  tnact[idx].g1 = green(elm[idx].colour);
  tnact[idx].b1 = blue(elm[idx].colour);
  tnact[idx].r2 = red(c2); tnact[idx].g2 = green(c2); tnact[idx].b2 = blue(c2);
  tnact[idx].totTime = dur;
  tnact[idx].elapsedTime = 0;
}
////////////

void setup() {
  size(
    barWidth * arrSize + barPadding * (arrSize + 1) + partPadding,
    int(maxElm * heightFactor) + barPadding * 2);
  noStroke();
  for (int i = 0; i < arrSize; ++i) {
    elm[i] = new Element();
    elm[i].value = int(random(maxElm) + 1);
    elm[i].colour = unsortedColour;
    elm[i].x = barWidth * i + barPadding * (i + 1) + partPadding;
    elm[i].y = maxY - elm[i].value * heightFactor;
    unsorted[i] = i;
    mvact[i] = new MoveAction();
    tnact[i] = new TintAction();
    println(i, elm[i].value);
  }
  lastMillis = lastOpMillis = millis();
  unsortedItr = 1;
  unsortedMinIdx = 0;
  activateTint(0, unsortedMinColour, actionDur);
}

void draw() {
  //clear();
  background(255);
  int curMillis = millis();
  anim_update(curMillis - lastMillis);
  if (curMillis - lastOpMillis >= opInterval) {
    lastOpMillis = curMillis;
    do_step();
  } 
  lastMillis = curMillis;

  for (int i = 0; i < arrSize; ++i) {
    fill(elm[i].colour);
    rect(elm[i].x, elm[i].y, barWidth, elm[i].value * heightFactor);
  }
}

float weighted(float a, float b, float w) { return a * (1 - w) + b * w; }
float weighted_sine(float a, float b, float w) { return a * (1 - sin(w * HALF_PI)) + b * sin(w * HALF_PI); }

void anim_update(int dt) {
  float progress;
  int r, g, b;
  for (int i = 0; i < arrSize; ++i) {
    if (mvact[i].isRunning) {
      progress = mvact[i].step(dt);
      if (progress >= 1) {
        progress = 1;
      }
      elm[i].x = weighted_sine(mvact[i].x1, mvact[i].x2, progress);
      elm[i].y = weighted_sine(mvact[i].y1, mvact[i].y2, progress);
      mvact[i].isRunning = (progress < 1);
    }
    if (tnact[i].isRunning) {
      progress = tnact[i].step(dt);
      if (progress >= 1) {
        progress = 1;
      }
      r = (int)weighted(tnact[i].r1, tnact[i].r2, progress);
      g = (int)weighted(tnact[i].g1, tnact[i].g2, progress);
      b = (int)weighted(tnact[i].b1, tnact[i].b2, progress);
      elm[i].colour = color(r, g, b);
      tnact[i].isRunning = (progress < 1);
    }
  }
}

void do_step() {
  if (unsortedCount == 0) return;
  activateTint(unsorted[unsortedItr - 1],
    unsortedMinIdx == unsortedItr - 1 ? unsortedMinColour : unsortedColour,
    actionDur);
  if (unsortedItr == unsortedCount) {
    // unsorted[unsortedMinIdx] is Sorted!
    activateTint(unsorted[unsortedMinIdx], sortedColour, actionDur);
    // Swap unsorted[unsortedMinIdx] and unsorted[0]
    activateMove(unsorted[unsortedMinIdx], elm[unsorted[0]].x - partPadding, elm[unsorted[unsortedMinIdx]].y, actionDur);
    if (unsortedMinIdx != 0)
      activateMove(unsorted[0], elm[unsorted[unsortedMinIdx]].x, elm[unsorted[0]].y, actionDur);
    unsorted[unsortedMinIdx] = unsorted[0];
    // Shift the array
    for (int i = 1; i < unsortedCount; ++i)
      unsorted[i - 1] = unsorted[i];
    --unsortedCount;
    if (unsortedCount > 0) {
      // Reset
      activateTint(unsorted[unsortedCount - 1], unsortedColour, actionDur);
      activateTint(unsorted[0], unsortedMinColour, actionDur);
      unsortedItr = 1;
      unsortedMinIdx = 0;
    }
  } else {
    activateTint(unsorted[unsortedItr], scannerColour, actionDur);
    if (elm[unsorted[unsortedMinIdx]].value > elm[unsorted[unsortedItr]].value) {
      activateTint(unsorted[unsortedMinIdx], unsortedColour, actionDur);
      unsortedMinIdx = unsortedItr;
    }
    ++unsortedItr;
  }
}

