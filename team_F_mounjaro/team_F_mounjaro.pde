Player player;
ArrayList<Obstacle> obstacles;

int score = 0;
int gameState = 0; // 0: タイトル, 1: プレイ中, 2: ゲームオーバー

float gameSpeed = 14;      // 奥から手前への流れるスピード
float[] lanes = {-90, 0, 90};

void setup(){
  size(400,1000,P3D);
  resetGame();
}

void draw() {
  background(20, 25, 40); // ダークな夜空風背景

  // 1. ゲーム状態別の処理
  if (gameState == 0) {
    drawTitleScreen();
  } else if (gameState == 1) {
    updateAndDraw3DGame();
    drawHUD();
  } else if (gameState == 2) {
    drawGameOverScreen();
  }
}

void updateAndDraw3DGame() {
  // スコアとスピードの更新
  score++;
  gameSpeed = 14 + (score / 300.0);

  // --- 3D視点（カメラ）とライティングの設定 ---
  lights();
  directionalLight(255, 255, 255, -1, 1, -1);
  
  // カメラ位置: (X, Y, Z) = (0, -220, 320) から (0, -40, -300) の奥を見下ろす
  camera(0, -220, 320,  0, -40, -300,  0, 1, 0);

  // --- 3Dオブジェクトの描画 ---
  draw3DTrack(); // コース（床）

  player.update();
  player.display();

  // 障害物の定期生成（ランダムなレーンに出現）
  if (frameCount % 45 == 0) {
    obstacles.add(new Obstacle());
  }

  // 障害物の更新・判定・描画
  for (int i = obstacles.size() - 1; i >= 0; i--) {
    Obstacle obs = obstacles.get(i);
    obs.update();
    obs.display();

    // 当たり判定
    if (obs.collidesWith(player)) {
      gameState = 2; // ゲームオーバー
    }

    // 画面手前に通り過ぎたら削除
    if (obs.isOffScreen()) {
      obstacles.remove(i);
    }
  }
}

// ------------------------------------------
// 3Dコース（地面・レーン線）の描画
// ------------------------------------------
void draw3DTrack() {
  pushMatrix();
  // アスファルトの床
  translate(0, 0, -600);
  fill(40, 45, 55);
  noStroke();
  box(320, 4, 1800);
  popMatrix();

  // スクロールする白線（スピード感の演出）
  stroke(255, 180);
  strokeWeight(3);
  float offset = (frameCount * gameSpeed) % 120;
  for (float z = -1400; z < 300; z += 120) {
    float lineZ = z + offset;
    line(-45, 0, lineZ, -45, 0, lineZ + 50);
    line( 45, 0, lineZ,  45, 0, lineZ + 50);
  }
}

// ------------------------------------------
// 2D UI (スコア・タイトル・ゲームオーバー) の描画
// ------------------------------------------
void drawHUD() {
  // 2D描画用にカメラとZバッファをリセット
  hint(DISABLE_DEPTH_TEST);
  camera();
  noLights();

  fill(255);
  textSize(22);
  textAlign(LEFT, TOP);
  text("SCORE: " + score, 20, 20);

  hint(ENABLE_DEPTH_TEST);
}

void drawTitleScreen() {
  hint(DISABLE_DEPTH_TEST);
  camera();
  noLights();

  textAlign(CENTER, CENTER);
  fill(255);
  textSize(36);
  text("3D RUNNER", width / 2, height / 2 - 50);

  textSize(18);
  fill(200);
  text("Press SPACE to Start", width / 2, height / 2 + 20);
  text("[←][→] : Move Lane\n[SPACE] / [↑] : Jump", width / 2, height / 2 + 70);

  hint(ENABLE_DEPTH_TEST);
}

void drawGameOverScreen() {
  hint(DISABLE_DEPTH_TEST);
  camera();
  noLights();

  fill(0, 180);
  rect(0, 0, width, height);

  textAlign(CENTER, CENTER);
  fill(255, 80, 80);
  textSize(42);
  text("GAME OVER", width / 2, height / 2 - 40);

  fill(255);
  textSize(22);
  text("Score: " + score, width / 2, height / 2 + 20);
  
  textSize(18);
  fill(200);
  text("Press SPACE to Restart", width / 2, height / 2 + 70);

  hint(ENABLE_DEPTH_TEST);
}

// ------------------------------------------
// キー入力処理
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
  player = new Player();
  obstacles = new ArrayList<Obstacle>();
}

// ==========================================
// 3D クラス定義
// ==========================================

// 1. プレイヤー（自機）
class Player {
  int currentLane = 1; // 0:左, 1:中央, 2:右
  float x = 0;
  float targetX = 0;
  float y = -25;
  float z = 0; // プレイヤーのZ位置は手前で固定
  float vy = 0;
  float gravity = 0.85;
  float jumpPower = -13;
  boolean isGrounded = true;

  float w = 36, h = 50, d = 36;

  void update() {
    // レーン移動（TargetXに向かって滑らかに補間移動）
    targetX = lanes[currentLane];
    x += (targetX - x) * 0.25;

    // ジャンプの物理演算
    vy += gravity;
    y += vy;
    if (y >= -25) { // 地面に着地
      y = -25;
      vy = 0;
      isGrounded = true;
    }
  }

  void moveLeft() {
    if (currentLane > 0) currentLane--;
  }

  void moveRight() {
    if (currentLane < 2) currentLane++;
  }

  void jump() {
    if (isGrounded) {
      vy = jumpPower;
      isGrounded = false;
    }
  }

  void display() {
    pushMatrix();
    translate(x, y, z);
    fill(60, 150, 255); // 青いプレイヤーブロック
    stroke(20);
    box(w, h, d);
    popMatrix();
  }
}

// 2. 障害物（奥から流れてくるキューブ）
class Obstacle {
  float x;
  float y = -25;
  float z = -1400; // 奥の出現位置
  float w = 45, h = 50, d = 45;

  Obstacle() {
    int lane = int(random(3));
    x = lanes[lane];
  }

  void update() {
    z += gameSpeed; // 手前に向かって移動
  }

  void display() {
    pushMatrix();
    translate(x, y, z);
    fill(230, 60, 60); // 赤い障害物
    stroke(20);
    box(w, h, d);
    popMatrix();
  }

  boolean isOffScreen() {
    return z > 200; // 画面手前を過ぎたら削除
  }

  // 3D空間（AABB）の当たり判定
  boolean collidesWith(Player p) {
    boolean xOverlap = abs(p.x - x) < (p.w + w) / 2;
    boolean yOverlap = abs(p.y - y) < (p.h + h) / 2;
    boolean zOverlap = abs(p.z - z) < (p.d + d) / 2;
    return xOverlap && yOverlap && zOverlap;
  }
}
