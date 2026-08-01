// ==========================================
// MOUNJARUN - Tutorial Image Version
// Processing 3+ (P3Dモード)
// ==========================================
import processing.sound.*;

Player player;
ArrayList<Obstacle> obstacles;
ArrayList<Item> items;

PImage[] tutorialImages = new PImage[7];
PImage storyImage;

PImage gameOverImage;
PImage clearImage;

int score = 0;
// 0: タイトル, 1: カウントダウン, 2: プレイ中, 3: ゲームオーバー, 4: ゲームクリア, 5: 説明画面
int gameState = 0;

float gameSpeed = 16;
float[] lanes = {-100, 0, 100};
float laneWidth = 90;

float maxTime = 60.0;
float timeRemaining = 60.0;

float maxHp = 100.0;
float hp = 50.0;
float hpDrainRate = 2.7;

float safeHpMin = 50.0;
float safeHpMax = 75.0;

float visualSafeHpMin = 25.0;
float visualSafeHpMax = 50.0;

float screenShake = 0.0;
String gameOverReason = "";

float countdownTimer = 3.99;

float debuffTimer = 0.0;
float debuffMaxTime = 10.0;
int hitCount = 0;

int numBgItems = 32;
float[] bgX = new float[numBgItems];
float[] bgY = new float[numBgItems];
float[] bgSpeed = new float[numBgItems];
int[] bgType = new int[numBgItems];
float[] bgRot = new float[numBgItems];

int tutorialPage = 0;

PImage obstacleImg;
PImage itemImg;

SoundFile titleBGM;
SoundFile playBGM;

SoundFile clickSE;
SoundFile gameOverSE;
SoundFile clearSE;

void setup() {
  size(450, 800, P3D);
  surface.setTitle("MOUNJARUN");

  for (int i = 0; i < 7; i++) {
    tutorialImages[i] = loadImage("tutorial" + (i + 1) + ".png");
  }

  gameOverImage = loadImage("gameover.png");
  clearImage = loadImage("clear.png");

  for (int i = 0; i < numBgItems; i++) {
    bgX[i] = random(width);
    bgY[i] = random(height);
    bgSpeed[i] = random(0.6, 1.5);
    bgType[i] = int(random(5));
    bgRot[i] = random(TWO_PI);
  }
  obstacleImg = loadImage("obstacle.png");
  itemImg = loadImage("item.png");
  storyImage = loadImage("story.png");

  resetGame();
}

void texturedBox(PImage img, float w, float h, float d) {

  beginShape(QUADS);
  texture(img);

  // 前
  vertex(-w/2, -h/2, d/2, 0, 0);
  vertex( w/2, -h/2, d/2, img.width, 0);
  vertex( w/2, h/2, d/2, img.width, img.height);
  vertex(-w/2, h/2, d/2, 0, img.height);

  // 後
  vertex( w/2, -h/2, -d/2, 0, 0);
  vertex(-w/2, -h/2, -d/2, img.width, 0);
  vertex(-w/2, h/2, -d/2, img.width, img.height);
  vertex( w/2, h/2, -d/2, 0, img.height);

  // 左
  vertex(-w/2, -h/2, -d/2, 0, 0);
  vertex(-w/2, -h/2, d/2, img.width, 0);
  vertex(-w/2, h/2, d/2, img.width, img.height);
  vertex(-w/2, h/2, -d/2, 0, img.height);

  // 右
  vertex( w/2, -h/2, d/2, 0, 0);
  vertex( w/2, -h/2, -d/2, img.width, 0);
  vertex( w/2, h/2, -d/2, img.width, img.height);
  vertex( w/2, h/2, d/2, 0, img.height);

  // 上
  vertex(-w/2, -h/2, -d/2, 0, 0);
  vertex( w/2, -h/2, -d/2, img.width, 0);
  vertex( w/2, -h/2, d/2, img.width, img.height);
  vertex(-w/2, -h/2, d/2, 0, img.height);

  // 下
  vertex(-w/2, h/2, d/2, 0, 0);
  vertex( w/2, h/2, d/2, img.width, 0);
  vertex( w/2, h/2, -d/2, img.width, img.height);
  vertex(-w/2, h/2, -d/2, 0, img.height);

  endShape();
}

void draw() {
  background(225, 245, 235);

  if (gameState == 0) {
    drawDietBackground();
    drawTitleScreen();
  } else if (gameState == 5) {
    drawDietBackground();
    drawHowToPlayScreen();
  } else if (gameState == 1) {
    drawDietBackground();
    drawGrassyField();
    player.display();
    drawHUD();
    drawCountdown();
  } else if (gameState == 2) {
    updateAndDraw3DGame();
    drawHUD();
  } else if (gameState == 3) {
    drawDietBackground();
    drawGameOverScreen();
  } else if (gameState == 4) {
    drawDietBackground();
    drawClearScreen();
  } else if (gameState == 6) {
    drawDietBackground();
    drawStoryScreen();
  }
}

void drawCountdown() {
  hint(DISABLE_DEPTH_TEST);
  camera();
  perspective();
  noLights();

  float dt = (frameRate > 0) ? (1.0 / frameRate) : (1.0 / 60.0);
  countdownTimer -= dt;

  textAlign(CENTER, CENTER);

  fill(0, 100);
  rectMode(CORNER);
  rect(0, 0, width, height);

  textSize(64);
  if (countdownTimer > 3.0) {
    fill(255, 100, 100);
    text("3", width / 2, height / 2);
  } else if (countdownTimer > 2.0) {
    fill(255, 200, 100);
    text("2", width / 2, height / 2);
  } else if (countdownTimer > 1.0) {
    fill(255, 255, 100);
    text("1", width / 2, height / 2);
  } else if (countdownTimer > 0.0) {
    fill(100, 255, 150);
    textSize(48);
    text("Let's go!", width / 2, height / 2);
  } else {
    gameState = 2;
  }

  hint(ENABLE_DEPTH_TEST);
}

void drawDietBackground() {
  hint(DISABLE_DEPTH_TEST);
  camera();
  perspective();
  noLights();

  stroke(200, 230, 215);
  strokeWeight(2);
  for (int x = 0; x < width; x += 40) line(x, 0, x, height);
  for (int y = 0; y < height; y += 40) line(0, y, width, y);

  noStroke();
  for (int i = 0; i < numBgItems; i++) {
    bgY[i] -= bgSpeed[i];
    bgRot[i] += 0.015;
    if (bgY[i] < -30) {
      bgY[i] = height + 30;
      bgX[i] = random(width);
    }

    pushMatrix();
    translate(bgX[i], bgY[i]);
    rotate(sin(bgRot[i]) * 0.3);

    if (bgType[i] == 0) {
      fill(255);
      ellipse(0, 0, 22, 22);
      fill(40);
      rectMode(CENTER);
      rect(0, 5, 8, 8, 2);
      rectMode(CORNER);
    } else if (bgType[i] == 1) {
      fill(240, 80, 80);
      ellipse(0, 2, 20, 18);
      fill(100, 180, 60);
      ellipse(2, -8, 6, 4);
    } else if (bgType[i] == 2) {
      fill(80, 180, 90);
      ellipse(0, -3, 18, 16);
      fill(230, 220, 190);
      rectMode(CENTER);
      rect(0, 8, 6, 10, 2);
      rectMode(CORNER);
    } else if (bgType[i] == 3) {
      fill(240, 240, 245);
      stroke(180, 190, 200);
      strokeWeight(1.5);
      rectMode(CENTER);
      rect(0, 0, 20, 20, 4);
      fill(80, 200, 120);
      noStroke();
      rect(0, -4, 12, 5, 1);
      rectMode(CORNER);
    } else {
      rectMode(CENTER);
      fill(220, 225, 230);
      stroke(140, 160, 180);
      strokeWeight(1);
      rect(0, 2, 8, 20, 2);
      fill(0, 180, 240);
      rect(0, -5, 8, 6, 2);
      stroke(180);
      strokeWeight(1.5);
      line(0, -8, 0, -15);
      rectMode(CORNER);
    }
    popMatrix();
  }

  stroke(100, 170, 130);
  strokeWeight(8);
  noFill();
  rect(12, 12, width - 24, height - 24, 20);

  hint(ENABLE_DEPTH_TEST);
}

void updateAndDraw3DGame() {
  score++;

  float baseSpeed = (timeRemaining <= 20.0) ? 18.0 : 12.0;
  gameSpeed = baseSpeed + (score / 350.0);

  float dt = (frameRate > 0) ? (1.0 / frameRate) : (1.0 / 60.0);
  timeRemaining -= dt;

  if (debuffTimer > 0) {
    debuffTimer -= dt;
    if (debuffTimer <= 0) {
      debuffTimer = 0;
      hitCount = 0;
    }
  }

  if (timeRemaining <= 0) {
    timeRemaining = 0;
    if (hp >= safeHpMin && hp <= safeHpMax) {
      gameState = 4;
    } else {
      gameOverReason = "OUT OF SAFE ZONE!";
      gameState = 3;
    }
    return;
  }

  hp -= hpDrainRate * dt;

  if (hp <= 0) {
    hp = 0;
    gameOverReason = "HP EMPTY!";
    gameState = 3;
    return;
  }
  if (hp >= maxHp) {
    hp = maxHp;
    gameOverReason = "HP OVERHEAT!";
    gameState = 3;
    return;
  }
  if (safeHpMin >= safeHpMax) {
    gameOverReason = "NO SAFE ZONE!";
    gameState = 3;
    return;
  }

  drawDietBackground();

  lights();
  directionalLight(255, 250, 220, -0.3, 1, -0.8);
  ambientLight(150, 170, 150);

  float shakeX = random(-screenShake, screenShake);
  float shakeY = random(-screenShake, screenShake);
  screenShake *= 0.88;

  camera(0 + shakeX, -230 + shakeY, 310, 0, -40, -300, 0, 1, 0);

  drawGrassyField();

  player.update();
  player.display();

  if (frameCount % 12 == 0) {
    if (random(1) < 0.60) {
      items.add(new Item());
    } else {
      obstacles.add(new Obstacle());
    }
  }

  for (int i = obstacles.size() - 1; i >= 0; i--) {
    Obstacle obs = obstacles.get(i);
    obs.update();
    obs.display();

    if (obs.collidesWith(player)) {
      hp -= 8.0;
      screenShake = 14.0;
      debuffTimer = 10.0;
      hitCount++;
      obstacles.remove(i);
    } else if (obs.isOffScreen()) {
      obstacles.remove(i);
    }
  }

  for (int i = items.size() - 1; i >= 0; i--) {
    Item item = items.get(i);
    item.update();
    item.display();

    if (item.collidesWith(player)) {
      if (debuffTimer > 0) {
        float reducedHeal = 3.0 - (hitCount - 1) * 0.5;
        if (reducedHeal < 1.0) {
          reducedHeal = 1.0;
        }
        hp += reducedHeal;
      } else {
        hp += 4.0;
      }
      items.remove(i);
    } else if (item.isOffScreen()) {
      items.remove(i);
    }
  }
}

void drawGrassyField() {
  float trackDepth = 1800;
  float offset = (frameCount * gameSpeed) % 120;

  pushMatrix();
  translate(0, 2, -600);
  fill(90, 175, 75, 230);
  noStroke();
  box(2000, 4, trackDepth);
  popMatrix();

  for (int i = 0; i < 3; i++) {
    pushMatrix();
    translate(lanes[i], 0, -600);
    if (i == 1) fill(175, 130, 85);
    else        fill(160, 115, 75);
    noStroke();
    box(laneWidth, 6, trackDepth);
    popMatrix();
  }

  stroke(100, 65, 35);
  strokeWeight(5);
  float borderX1 = (lanes[0] + lanes[1]) / 2.0;
  float borderX2 = (lanes[1] + lanes[2]) / 2.0;
  line(borderX1, -4, -1500, borderX1, -4, 300);
  line(borderX2, -4, -1500, borderX2, -4, 300);

  stroke(130, 85, 45);
  strokeWeight(6);
  float leftOuter  = lanes[0] - laneWidth / 2.0;
  float rightOuter = lanes[2] + laneWidth / 2.0;
  line(leftOuter, -4, -1500, leftOuter, -4, 300);
  line(rightOuter, -4, -1500, rightOuter, -4, 300);

  stroke(140, 95, 55, 180);
  strokeWeight(3);
  for (float z = -1400; z < 300; z += 120) {
    float lineZ = z + offset;
    for (int i = 0; i < 3; i++) {
      line(lanes[i] - laneWidth / 2.0 + 10, -4, lineZ, lanes[i] + laneWidth / 2.0 - 10, -4, lineZ);
    }
  }
}

void drawHUD() {
  hint(DISABLE_DEPTH_TEST);
  camera();
  perspective();
  noLights();

  if (timeRemaining <= 20.0 && timeRemaining > 0 && gameState == 2) {
    if (frameCount % 20 < 10) {
      noFill();
      stroke(255, 50, 50, 160);
      strokeWeight(12);
      rectMode(CORNER);
      rect(0, 0, width, height);
    }
  }

  if (screenShake > 2.0) {
    fill(255, 0, 0, map(screenShake, 0, 18, 0, 80));
    noStroke();
    rectMode(CORNER);
    rect(0, 0, width, height);
  }

  float hudHeight = (debuffTimer > 0) ? 160 : 120;

  rectMode(CORNER);
  fill(15, 23, 42, 220);
  stroke(255, 255, 255, 60);
  strokeWeight(2);
  rect(15, 15, 170, hudHeight, 12);

  fill(0, 255, 180);
  textSize(15);
  textAlign(LEFT, TOP);
  text("MOUNJARUN", 25, 25);

  fill(255);
  textSize(16);
  text("SCORE: " + score, 25, 52);

  fill(255, 220, 80);
  textSize(13);
  text("TIME LEFT:", 25, 82);

  if (timeRemaining <= 20.0 && frameCount % 12 < 6) fill(255, 50, 50);
  else fill(255, 235, 100);
  textSize(22);
  text(nf(timeRemaining, 0, 1) + "s", 25, 100);
  if (debuffTimer > 0) {
    fill(255, 100, 100);
    textSize(11);
    textAlign(LEFT, TOP);
    text("DEBUFF: " + nf(debuffTimer, 0, 1) + "s (x" + hitCount + ")", 25, 134);

    fill(60, 20, 20);
    noStroke();
    rect(25, 149, 150, 8, 4);

    float ratio = debuffTimer / debuffMaxTime;
    int pulse = int(180 + sin(frameCount * 0.4) * 75);
    fill(255, 60, 60, pulse);
    rect(25, 149, 150 * ratio, 8, 4);
  }

  float scaleCenterX = width - 110;
  float scaleCenterY = 110;
  float diameter = 180;

  pushMatrix();
  translate(scaleCenterX, scaleCenterY);

  fill(0, 0, 0, 60);
  noStroke();
  ellipse(5, 5, diameter + 10, diameter + 10);

  fill(200, 210, 220);
  stroke(80, 95, 110);
  strokeWeight(4);
  ellipse(0, 0, diameter + 6, diameter + 6);

  fill(250, 250, 252);
  stroke(40, 50, 60);
  strokeWeight(2);
  ellipse(0, 0, diameter, diameter);

  if (visualSafeHpMin < visualSafeHpMax) {
    float vAngMin = map(visualSafeHpMin, 0, maxHp, PI, PI + TWO_PI);
    float vAngMax = map(visualSafeHpMax, 0, maxHp, PI, PI + TWO_PI);

    noStroke();
    fill(70, 160, 250, 240);
    arc(0, 0, diameter - 6, diameter - 6, vAngMin, vAngMax, PIE);
  }

  stroke(60, 70, 80);
  for (int i = 0; i <= 10; i++) {
    float val = map(i, 0, 10, 0, maxHp);
    float ang = map(val, 0, maxHp, PI, PI + TWO_PI);

    float innerR = (i % 2 == 0) ? (diameter / 2 - 16) : (diameter / 2 - 10);
    float outerR = (diameter / 2 - 4);

    strokeWeight((i % 2 == 0) ? 2.5 : 1);
    line(cos(ang) * innerR, sin(ang) * innerR, cos(ang) * outerR, sin(ang) * outerR);
  }

  if (visualSafeHpMin < visualSafeHpMax) {
    float vAngMin = map(visualSafeHpMin, 0, maxHp, PI, PI + TWO_PI);
    float vAngMax = map(visualSafeHpMax, 0, maxHp, PI, PI + TWO_PI);

    stroke(20, 80, 160);
    strokeWeight(2.5);
    line(0, 0, cos(vAngMin) * (diameter/2 - 16), sin(vAngMin) * (diameter/2 - 16));
    line(0, 0, cos(vAngMax) * (diameter/2 - 16), sin(vAngMax) * (diameter/2 - 16));
  }

  float needleAng = map(hp, 0, maxHp, PI, PI + TWO_PI);
  pushMatrix();
  rotate(needleAng);

  stroke(230, 40, 50);
  strokeWeight(4);
  line(0, 10, 0, -(diameter / 2 - 12));

  fill(230, 40, 50);
  noStroke();
  triangle(-6, -(diameter / 2 - 20), 6, -(diameter / 2 - 20), 0, -(diameter / 2 - 6));
  popMatrix();

  fill(50, 60, 70);
  stroke(255);
  strokeWeight(2);
  ellipse(0, 0, 18, 18);

  boolean inSafeZone = (hp >= safeHpMin && hp <= safeHpMax);

  rectMode(CENTER);
  if (inSafeZone) {
    fill(10, 40, 25, 230);
    stroke(0, 230, 120);
    strokeWeight(2);
  } else {
    fill(50, 15, 20, 230);
    stroke(255, 70, 80);
    strokeWeight(2);
  }
  rect(0, 35, 76, 26, 6);

  if (inSafeZone) fill(0, 255, 160);
  else fill(255, 90, 90);

  textSize(16);
  textAlign(CENTER, CENTER);
  text(nf(hp, 0, 1) + "kg", 0, 33);

  popMatrix();

  hint(ENABLE_DEPTH_TEST);
}

void drawTitleScreen() {
  hint(DISABLE_DEPTH_TEST);
  camera();
  perspective();
  noLights();

  textAlign(CENTER, CENTER);
  float titleY = height / 2 - 160;

  fill(180, 220, 200);
  textSize(48);
  text("MOUNJARUN", width / 2 + 3, titleY + 3);
  fill(40, 120, 80);
  textSize(48);
  text("MOUNJARUN", width / 2, titleY);

  float runnerX = width / 2;
  float runnerY = height / 2 + 10 + sin(frameCount * 0.15) * 5;

  noStroke();
  fill(110, 60, 30);
  ellipse(runnerX, runnerY - 10, 42, 42);
  ellipse(runnerX - 20, runnerY - 8, 18, 28);
  ellipse(runnerX + 20, runnerY - 8, 18, 28);
  fill(255, 220, 190);
  ellipse(runnerX, runnerY - 8, 30, 30);
  fill(255, 110, 130);
  rectMode(CENTER);
  rect(runnerX, runnerY + 18, 24, 26, 4);
  rectMode(CORNER);

  if (frameCount % 50 < 32) {
    fill(210, 100, 20);
    textSize(20);
    text("〜 Press ENTER to Start 〜", width / 2, height / 2 + 180);
  }

  hint(ENABLE_DEPTH_TEST);
}

void drawStoryScreen() {

  hint(DISABLE_DEPTH_TEST);
  camera();
  perspective();
  noLights();

  imageMode(CORNER);
  image(storyImage, 0, 0, width, height);

  fill(255);
  textAlign(RIGHT, BOTTOM);
  textSize(18);
  text("ENTER：次へ\nSPACE：スキップ", width-20, height-20);

  hint(ENABLE_DEPTH_TEST);
}

void drawHowToPlayScreen() {

  imageMode(CORNER);
  image(tutorialImages[tutorialPage], 0, 0, width, height);
  fill(255);
  textAlign(RIGHT, BOTTOM);
  textSize(16);
  text("ENTER：次へ\nSPACE：スキップ", width-20, height-20);
}

void drawGameOverScreen() {
  hint(DISABLE_DEPTH_TEST);
  camera();
  perspective();
  noLights();
  fill(255);
  text("Press ENTER", width/2, height-60);
  imageMode(CORNER);
  image(gameOverImage, 0, 0, width, height);
}

void drawClearScreen() {
  hint(DISABLE_DEPTH_TEST);
  camera();
  perspective();
  noLights();
  fill(255);
  text("Press ENTER", width/2, height-60);
  imageMode(CORNER);
  image(clearImage, 0, 0, width, height);
}

void keyPressed() {
  if (gameState == 0) {
    if (keyCode == ENTER || key == RETURN) gameState = 6;
  } else if (gameState==5) {
    if (keyCode == ENTER || key == RETURN) {
      tutorialPage++;
      if (tutorialPage>=7) {
        tutorialPage=0;
        resetGame();
        gameState=1;
      }
    } 
    // Space：説明をスキップ
    if (key == ' ') {
      tutorialPage = 0;
      resetGame();
      gameState = 1;
    }
  } else if (gameState == 2) {
    if (keyCode == LEFT || key == 'a')  player.moveLeft();
    if (keyCode == RIGHT || key == 'd') player.moveRight();
  } else if (gameState == 3 || gameState == 4) {
    if (keyCode == ENTER || key == RETURN) {
      resetGame();
      gameState = 0;
    }
  }else if (gameState == 6) {

      // Enterで説明へ
      if (keyCode == ENTER || key == RETURN) {
        tutorialPage = 0;
        gameState = 5;
      }

      // Spaceで全部スキップ
      if (key == ' ') {
        tutorialPage = 0;
        resetGame();
        gameState = 1;
      }
    }
}

void resetGame() {
  score = 0;
  gameSpeed = 16;
  timeRemaining = maxTime;
  hp = 50.0;
  safeHpMin = 50.0;
  safeHpMax = 75.0;
  visualSafeHpMin = 25.0;
  visualSafeHpMax = 50.0;
  screenShake = 0.0;
  gameOverReason = "";
  debuffTimer = 0.0;
  hitCount = 0;
  countdownTimer = 3.99;
  player = new Player();
  obstacles = new ArrayList<Obstacle>();
  items = new ArrayList<Item>();
}

class Player {
  int currentLane = 1;
  float x = 0, targetX = 0;
  float y = -30, z = 0;
  float w = 50, h = 60, d = 70;
  float rollAngle = 0;
  float animTimer = 0;

  void update() {
    targetX = lanes[currentLane];
    float dx = targetX - x;
    x += dx * 0.28;
    rollAngle = dx * 0.015;
    animTimer += 0.2;
  }

  void moveLeft() {
    if (currentLane > 0) currentLane--;
  }
  void moveRight() {
    if (currentLane < 2) currentLane++;
  }

  void display() {
    pushMatrix();
    translate(x, y, z);
    rotateZ(rollAngle);

    pushMatrix();
    translate(0, 20, 0);
    fill(245, 250, 255);
    stroke(160, 180, 200);
    strokeWeight(1.5);
    box(54, 8, 75);
    translate(0, -5, -22);
    fill(30, 40, 50);
    noStroke();
    box(24, 2, 12);
    fill(0, 255, 150);
    translate(0, -1, 0);
    box(18, 1, 8);
    popMatrix();

    pushMatrix();
    translate(0, -8, 0);

    fill(255, 220, 190);
    noStroke();
    pushMatrix();
    translate(-8, 18, 5);
    box(7, 18, 8);
    fill(255);
    translate(0, 9, -2);
    box(8, 6, 12);
    popMatrix();
    pushMatrix();
    translate(8, 18, -5);
    fill(255, 220, 190);
    box(7, 18, 8);
    fill(40);
    translate(0, 9, -2);
    box(8, 6, 12);
    popMatrix();
    pushMatrix();
    translate(0, 2, 0);
    fill(60, 120, 255);
    box(24, 20, 16);
    fill(40, 60, 120);
    translate(0, 10, 0);
    box(21, 6, 15);
    popMatrix();

    pushMatrix();
    translate(0, -18, 0);
    fill(110, 60, 30);
    sphereDetail(12);
    sphere(15);
    fill(255, 220, 190);
    translate(0, 1, 3);
    sphere(12);
    fill(40, 30, 20);
    ellipse(-4, -1, 3, 5);
    ellipse(4, -1, 3, 5);

    fill(60, 40, 20);

    // 前髪
    pushMatrix();
    translate(0, -10, -8);
    box(22, 8, 6);
    popMatrix();

    // 頭頂部
    pushMatrix();
    translate(0, -18, 0);
    box(28, 10, 28);
    popMatrix();
    popMatrix();


    fill(255, 220, 190);
    pushMatrix();
    translate(-14, -2, 0);
    rotateZ(-0.2);
    box(6, 16, 6);
    popMatrix();
    pushMatrix();
    translate(14, -2, 0);
    rotateZ(0.2);
    box(6, 16, 6);
    popMatrix();
    popMatrix();

    popMatrix();
  }
}

class Obstacle {
  int lane;
  float x, y = -25, z = -1400;
  float w = 45, h = 45, d = 45;

  Obstacle() {
    lane = int(random(3));
    x = lanes[lane];
  }

  void update() {
    z += gameSpeed;
  }

  void display() {
    pushMatrix();
    translate(x, y, z);
    noStroke();
    texturedBox(obstacleImg, w, h, d);
    popMatrix();
  }

  boolean isOffScreen() {
    return z > 200;
  }

  boolean collidesWith(Player p) {
    return abs(p.x - x) < (p.w + w) / 2 && abs(p.y - y) < (p.h + h) / 2 && abs(p.z - z) < (p.d + d) / 2;
  }
}

class Item {
  int lane;
  float x, y = -25, z = -1400;
  float w = 35, h = 35, d = 35;

  Item() {
    lane = int(random(3));
    x = lanes[lane];
  }

  void update() {
    z += gameSpeed;
  }

  void display() {
    pushMatrix();
    translate(x, y, z);
    noStroke();
    texturedBox(itemImg, w, h, d);
    popMatrix();
  }

  boolean isOffScreen() {
    return z > 200;
  }

  boolean collidesWith(Player p) {
    return abs(p.x - x) < (p.w + w) / 2 && abs(p.y - y) < (p.h + h) / 2 && abs(p.z - z) < (p.d + d) / 2;
  }
}
