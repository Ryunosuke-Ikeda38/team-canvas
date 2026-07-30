// ==========================================
// 3Dランニングゲーム（原っぱ ＆ 土の小道 ver.）
// ==========================================

Player player;
ArrayList<Obstacle> obstacles;
ArrayList<Item> items;

int score = 0;
int gameState = 0; // 0: タイトル, 1: プレイ中, 2: ゲームオーバー

float gameSpeed = 14;           // 奥から手前への流れるスピード
float[] lanes = {-100, 0, 100};  // 3つのレーンのX座標（左・中央・右）
float laneWidth = 90;           // 1つのレーンの幅

// 制限時間（60秒）
float maxTime = 60.0;
float timeRemaining = 60.0;

// ポップアップ演出用
int effectTimer = 0;
String effectText = "";
color effectColor = color(255);

void setup() {
  size(450, 800, P3D); // 縦画面 ＆ 3D描画モード
  resetGame();
}

void draw() {
  // 青空の背景色
  background(135, 206, 235);

  if (gameState == 0) {
    drawTitleScreen();
  } else if (gameState == 1) {
    updateAndDraw3DGame();
    drawHUD();
  } else if (gameState == 2) {
    drawGameOverScreen();
  }
}

// ------------------------------------------
// 3D空間のメイン描画
// ------------------------------------------
void updateAndDraw3DGame() {
  score++;
  gameSpeed = 14 + (score / 300.0);

  // 1. ゲージの自動減少（時間経過）
  if (frameRate > 0) {
    timeRemaining -= 1.0 / frameRate;
  } else {
    timeRemaining -= 1.0 / 60.0;
  }

  // ゲージ0でゲームオーバー
  if (timeRemaining <= 0) {
    timeRemaining = 0;
    gameState = 2;
  }

  // 3Dライティング（温かみのある太陽光と草の照り返し）
  lights();
  directionalLight(255, 250, 220, -0.3, 1, -0.8);
  ambientLight(140, 160, 140);
  camera(0, -230, 310,  0, -40, -300,  0, 1, 0);

  // 2. 原っぱと3つの土の小道描画
  drawGrassyField();

  // 3. プレイヤー更新・描画（頭上ミニゲージ付き）
  player.update();
  player.display();

  // 4. オブジェクト生成（赤＝障害物、青＝回復アイテム）
  if (frameCount % 40 == 0) {
    if (random(1) < 0.65) {
      obstacles.add(new Obstacle());
    } else {
      items.add(new Item());
    }
  }

  // 5. 赤の四角（障害物）更新・判定
  for (int i = obstacles.size() - 1; i >= 0; i--) {
    Obstacle obs = obstacles.get(i);
    obs.update();
    obs.display();

    if (obs.collidesWith(player)) {
      timeRemaining -= 8.0; // 8秒減算
      triggerEffect("-8.0s!", color(255, 60, 60));
      obstacles.remove(i);
    } else if (obs.isOffScreen()) {
      obstacles.remove(i);
    }
  }

  // 6. 青の四角（回復アイテム）更新・判定
  for (int i = items.size() - 1; i >= 0; i--) {
    Item item = items.get(i);
    item.update();
    item.display();

    if (item.collidesWith(player)) {
      timeRemaining = min(maxTime, timeRemaining + 6.0); // 6秒回復
      triggerEffect("+6.0s!", color(30, 180, 255));
      items.remove(i);
    } else if (item.isOffScreen()) {
      items.remove(i);
    }
  }
}

// ポップアップ演出のセット
void triggerEffect(String txt, color col) {
  effectText = txt;
  effectColor = col;
  effectTimer = 30;
}

// ------------------------------------------
// 原っぱと土の小道の描画処理
// ------------------------------------------
void drawGrassyField() {
  float trackDepth = 1800;
  float offset = (frameCount * gameSpeed) % 120;

  // 1. 広大な原っぱ（一面に広がる緑の地面）
  pushMatrix();
  translate(0, 2, -600);
  fill(90, 175, 75);
  noStroke();
  box(2000, 4, trackDepth);
  popMatrix();

  // 2. 3つの土の小道
  for (int i = 0; i < 3; i++) {
    pushMatrix();
    translate(lanes[i], 0, -600);

    if (i == 1) fill(175, 130, 85); // 中央（明るい土色）
    else        fill(160, 115, 75); // 左右（少し濃い土色）

    noStroke();
    box(laneWidth, 6, trackDepth);
    popMatrix();
  }

  // 3. レーン間の境界線（丸太風ライン）
  stroke(100, 65, 35);
  strokeWeight(5);
  float borderX1 = (lanes[0] + lanes[1]) / 2.0;
  float borderX2 = (lanes[1] + lanes[2]) / 2.0;

  line(borderX1, -4, -1500, borderX1, -4, 300);
  line(borderX2, -4, -1500, borderX2, -4, 300);

  // 4. 小道の両端（外枠ライン）
  stroke(130, 85, 45);
  strokeWeight(6);
  float leftOuter  = lanes[0] - laneWidth / 2.0;
  float rightOuter = lanes[2] + laneWidth / 2.0;
  line(leftOuter, -4, -1500, leftOuter, -4, 300);
  line(rightOuter, -4, -1500, rightOuter, -4, 300);

  // 5. 木道・枕木ライン（スピード感演出）
  stroke(140, 95, 55, 180);
  strokeWeight(3);
  for (float z = -1400; z < 300; z += 120) {
    float lineZ = z + offset;
    for (int i = 0; i < 3; i++) {
      line(lanes[i] - laneWidth / 2.0 + 10, -4, lineZ, lanes[i] + laneWidth / 2.0 - 10, -4, lineZ);
    }
  }
}

// ------------------------------------------
// 2D UI（見やすい大型メインゲージ）
// ------------------------------------------
void drawHUD() {
  hint(DISABLE_DEPTH_TEST);
  camera();
  noLights();

  // 上部UI用バックグラウンドプレート
  fill(0, 120);
  noStroke();
  rect(10, 10, width - 20, 100, 10);

  // スコア表示
  fill(255);
  textSize(20);
  textAlign(LEFT, TOP);
  text("SCORE: " + score, 25, 20);

  // メインゲージ
  float gaugeX = 25;
  float gaugeY = 50;
  float gaugeWidth = width - 50;
  float gaugeHeight = 22;

  fill(20, 25, 35);
  stroke(255);
  strokeWeight(2);
  rect(gaugeX, gaugeY, gaugeWidth, gaugeHeight, 6);

  float currentGaugeWidth = map(timeRemaining, 0, maxTime, 0, gaugeWidth);
  currentGaugeWidth = constrain(currentGaugeWidth, 0, gaugeWidth);

  // ゲージの色（緑 → 黄 → 赤点滅）
  if (timeRemaining > maxTime * 0.5) {
    fill(0, 230, 110);
  } else if (timeRemaining > 10.0) {
    fill(255, 200, 0);
  } else {
    if (frameCount % 12 < 6) fill(255, 40, 50);
    else                    fill(150, 10, 20);
  }

  noStroke();
  if (currentGaugeWidth > 0) {
    rect(gaugeX + 2, gaugeY + 2, currentGaugeWidth - 4, gaugeHeight - 4, 4);
  }

  // タイムテキスト
  fill(255);
  textSize(13);
  textAlign(RIGHT, CENTER);
  text("TIME: " + nf(timeRemaining, 0, 1) + "s ", gaugeX + gaugeWidth - 6, gaugeY + gaugeHeight / 2);

  // ポップアップ演出 (+6.0s / -8.0s)
  if (effectTimer > 0) {
    textAlign(CENTER, CENTER);
    textSize(34);
    fill(effectColor, map(effectTimer, 0, 30, 0, 255));
    text(effectText, width / 2, height / 2 - 90 - (30 - effectTimer) * 1.5);
    effectTimer--;
  }

  // レーン表示
  fill(255);
  textSize(12);
  textAlign(LEFT, TOP);
  text("LANE:", 25, 80);
  for (int i = 0; i < 3; i++) {
    if (i == player.currentLane) fill(255, 200, 0);
    else                        fill(120);
    rect(68 + i * 20, 82, 15, 10, 2);
  }

  hint(ENABLE_DEPTH_TEST);
}

void drawTitleScreen() {
  hint(DISABLE_DEPTH_TEST);
  camera();
  noLights();

  // 背景にうっすら暗めの膜を張る
  fill(0, 100);
  rect(0, 0, width, height);

  textAlign(CENTER, CENTER);
  fill(255);
  textSize(36);
  text("GRASSLAND RUN", width / 2, height / 2 - 80);

  textSize(16);
  fill(100, 230, 255);
  text("■ 青の四角： ゲージ回復 (+6s)", width / 2, height / 2 - 20);
  fill(255, 120, 120);
  text("■ 赤の四角： ゲージ減少 (-8s)", width / 2, height / 2 + 10);
  fill(240);
  text("※ 制限時間 60秒！時間経過でも減少します", width / 2, height / 2 + 40);

  textSize(16);
  text("[←][→] : 移動  /  [SPACE] : ジャンプ", width / 2, height / 2 + 90);
  fill(255, 220, 0);
  text("Press SPACE to Start", width / 2, height / 2 + 140);

  hint(ENABLE_DEPTH_TEST);
}

void drawGameOverScreen() {
  hint(DISABLE_DEPTH_TEST);
  camera();
  noLights();

  fill(0, 160);
  rect(0, 0, width, height);

  textAlign(CENTER, CENTER);
  fill(255, 80, 80);
  textSize(42);
  text("GAME OVER", width / 2, height / 2 - 40);

  fill(255);
  textSize(22);
  text("Final Score: " + score, width / 2, height / 2 + 20);

  textSize(18);
  fill(220);
  text("Press SPACE to Restart", width / 2, height / 2 + 70);

  hint(ENABLE_DEPTH_TEST);
}

// ------------------------------------------
// キー操作
// ------------------------------------------
void keyPressed() {
  if (gameState == 0) {
    if (key == ' ') gameState = 1;
  } else if (gameState == 1) {
    if (keyCode == LEFT || key == 'a')  player.moveLeft();
    if (keyCode == RIGHT || key == 'd') player.moveRight();
    if (keyCode == UP || key == ' ')    player.jump();
  } else if (gameState == 2) {
    if (key == ' ') {
      resetGame();
      gameState = 1;
    }
  }
}

void resetGame() {
  score = 0;
  gameSpeed = 14;
  timeRemaining = maxTime;
  player = new Player();
  obstacles = new ArrayList<Obstacle>();
  items = new ArrayList<Item>();
}

// ==========================================
// 3D クラス定義
// ==========================================

// 1. プレイヤー（頭上に追従ミニゲージ付き）
class Player {
  int currentLane = 1;
  float x = 0, targetX = 0;
  float y = -25, z = 0;
  float vy = 0, gravity = 0.85;
  float jumpPower = -13;
  boolean isGrounded = true;

  float w = 36, h = 50, d = 36;

  void update() {
    targetX = lanes[currentLane];
    x += (targetX - x) * 0.28;

    vy += gravity;
    y += vy;
    if (y >= -25) {
      y = -25;
      vy = 0;
      isGrounded = true;
    }
  }

  void moveLeft()  { if (currentLane > 0) currentLane--; }
  void moveRight() { if (currentLane < 2) currentLane++; }
  void jump()      { if (isGrounded) { vy = jumpPower; isGrounded = false; } }

  void display() {
    pushMatrix();
    translate(x, y, z);

    // 自機本体
    fill(255, 245, 230);
    stroke(120, 90, 60);
    strokeWeight(2);
    box(w, h, d);

    // ★ 頭上ミニゲージ
    translate(0, -42, 0);
    float barW = 60;
    float barH = 8;
    float ratio = constrain(timeRemaining / maxTime, 0, 1);

    rectMode(CENTER);
    fill(0, 180);
    stroke(255);
    strokeWeight(1.5);
    rect(0, 0, barW + 4, barH + 4, 3);

    rectMode(CORNER);
    noStroke();
    if (ratio > 0.5)      fill(0, 230, 110);
    else if (ratio > 0.2) fill(255, 200, 0);
    else                  fill(255, 40, 40);

    if (ratio > 0) {
      rect(-barW / 2.0, -barH / 2.0, barW * ratio, barH, 2);
    }

    popMatrix();
  }
}

// 2. 赤の四角（ダメージ障害物）
class Obstacle {
  int lane;
  float x, y = -25, z = -1400;
  float w = 50, h = 50, d = 50;

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
    fill(230, 60, 60);
    stroke(255, 200, 200);
    strokeWeight(1);
    box(w, h, d);
    popMatrix();
  }

  boolean isOffScreen() {
    return z > 200;
  }

  boolean collidesWith(Player p) {
    boolean xOverlap = abs(p.x - x) < (p.w + w) / 2;
    boolean yOverlap = abs(p.y - y) < (p.h + h) / 2;
    boolean zOverlap = abs(p.z - z) < (p.d + d) / 2;
    return xOverlap && yOverlap && zOverlap;
  }
}

// 3. 青の四角（回復アイテム）
class Item {
  int lane;
  float x, y = -25, z = -1400;
  float w = 40, h = 40, d = 40;
  float angle = 0;

  Item() {
    lane = int(random(3));
    x = lanes[lane];
  }

  void update() {
    z += gameSpeed;
    angle += 0.05;
  }

  void display() {
    pushMatrix();
    translate(x, y, z);
    rotateY(angle);
    fill(30, 180, 255);
    stroke(200, 240, 255);
    strokeWeight(1.5);
    box(w, h, d);
    popMatrix();
  }

  boolean isOffScreen() {
    return z > 200;
  }

  boolean collidesWith(Player p) {
    boolean xOverlap = abs(p.x - x) < (p.w + w) / 2;
    boolean yOverlap = abs(p.y - y) < (p.h + h) / 2;
    boolean zOverlap = abs(p.z - z) < (p.d + d) / 2;
    return xOverlap && yOverlap && zOverlap;
  }
}
