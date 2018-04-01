import frames.timing.*;
import frames.primitives.*;
import frames.processing.*;

// 1. Frames' objects
Scene scene;
Frame frame;
Vector v1, v2, v3;
// timing
TimingTask spinningTask;
boolean yDirection;
// scaling is a power of 2
int n = 4;

// 2. Hints
boolean triangleHint = true;
boolean gridHint = false;
boolean debug = true;
//Use a and s to increment or decrement the number of subpixeles for antialiasing
int numSubpixels = 1;
// 3. Use FX2D, JAVA2D, P2D or P3D
String renderer = P3D;

void setup() {
  //use 2^n to change the dimensions
  size(720,720, renderer);
  scene = new Scene(this);
  if (scene.is3D())
    scene.setType(Scene.Type.ORTHOGRAPHIC);
  scene.setRadius(width/2);
  scene.fitBallInterpolation();

  // not really needed here but create a spinning task
  // just to illustrate some frames.timing features. For
  // example, to see how 3D spinning from the horizon
  // (no bias from above nor from below) induces movement
  // on the frame instance (the one used to represent
  // onscreen pixels): upwards or backwards (or to the left
  // vs to the right)?
  // Press ' ' to play it :)
  // Press 'y' to change the spinning axes defined in the
  // world system.
  spinningTask = new TimingTask() {
    public void execute() {
      spin();
    }
  };
  scene.registerTask(spinningTask);

  frame = new Frame();
  frame.setScaling(width/pow(2, n));

  // init the triangle that's gonna be rasterized
  randomizeTriangle();
}

void draw() {
  background(0);
  stroke(0, 255, 0);
  if (gridHint)
    scene.drawGrid(scene.radius(), (int)pow( 2, n));
  if (triangleHint)
    drawTriangleHint();
  pushMatrix();
  pushStyle();
  scene.applyTransformation(frame);
  triangleRaster();
  popStyle();
  popMatrix();
}

// Implement this function to rasterize the triangle.
// Coordinates are given in the frame system which has a dimension of 2^n
void triangleRaster() {
  // frame.coordinatesOf converts from world to frame
  // here we convert v1 to illustrate the idea
  if (debug) {
    pushStyle();
    stroke(255, 255, 0, 125);
    point(round(frame.coordinatesOf(v1).x()), round(frame.coordinatesOf(v1).y()));
    popStyle();
   
    int relativeGrid = int(pow( 2, n));
    for( int x = -relativeGrid; x <relativeGrid; x++){
      for( int y = -relativeGrid;  y < relativeGrid; y++){
        // Funciones de Borde
        float e23 = orient2d(frame.coordinatesOf(v2),frame.coordinatesOf(v3), x, y) ;
        float e31 = orient2d(frame.coordinatesOf(v3), frame.coordinatesOf(v1), x,y);
        float e12 = orient2d(frame.coordinatesOf(v1), frame.coordinatesOf(v2), x,y);
        float DoubleAreaOfV1V2V3 = e23+e31+e12;
        // Pesos Baricentricos
        float w1 = e23 / DoubleAreaOfV1V2V3;
        float w2 = e31 / DoubleAreaOfV1V2V3;
        float w3 = e12 / DoubleAreaOfV1V2V3;
        pushStyle();
        // ColorPixel = ( w1*ColorV1 , w2*ColorV2, w3*ColorV3 ) 
        noStroke();
        float[] colors = {0, 0, 0};
        
        //antialiasing
        for(float subpixelx = -0.5; subpixelx < 0.5; subpixelx += (float)1/numSubpixels){
          for(float subpixely = -0.5; subpixely < 0.5; subpixely += (float)1/numSubpixels){
            e23 = orient2d(frame.coordinatesOf(v2), frame.coordinatesOf(v3),(x+subpixelx ), ( y + subpixely ));
            e31 = orient2d(frame.coordinatesOf(v3), frame.coordinatesOf(v1),(x+subpixelx ), ( y + subpixely ));
            e12 = orient2d(frame.coordinatesOf(v1), frame.coordinatesOf(v2),(x+subpixelx ), ( y + subpixely ));
            DoubleAreaOfV1V2V3 = abs(e23)+ abs(e31)+ abs(e12);
            if ( (e12 >= 0 && e23 >= 0 && e31 >= 0) || (e12 < 0 && e23 < 0 && e31 < 0) ){
                w1 = e23 / DoubleAreaOfV1V2V3;
                w2 = e31 / DoubleAreaOfV1V2V3;
                w3 = e12 / DoubleAreaOfV1V2V3;
                colors[0] += abs(w1*255);
                colors[1] += abs(w2*255);
                colors[2] += abs(w3*255);
            }
          }
        }

        colors[0] /= pow(numSubpixels,2);
        colors[1] /= pow(numSubpixels,2);
        colors[2] /= pow(numSubpixels,2);
        fill( colors[0], colors[1], colors[2]);
        rect(x ,y ,1,1);
        popStyle();        
      }
    }
  }
}

float orient2d(Vector a, Vector b, float x, float y){
  return (b.x()-a.x())*(y-a.y()) - (b.y()-a.y())*(x-a.x());
}

void randomizeTriangle() {
  int low = -width/2;
  int high = width/2;
  v1 = new Vector(random(low, high), random(low, high));
  v2 = new Vector(random(low, high), random(low, high));
  v3 = new Vector(random(low, high), random(low, high));
}

void drawTriangleHint() {
  pushStyle();
  noFill();
  strokeWeight(2);
  stroke(255, 0, 0);
  triangle(v1.x(), v1.y(), v2.x(), v2.y(), v3.x(), v3.y());
  strokeWeight(5);
  stroke(0, 255, 255);
  point(v1.x(), v1.y());
  point(v2.x(), v2.y());
  point(v3.x(), v3.y());
  popStyle();
}

void spin() {
  if (scene.is2D())
    scene.eye().rotate(new Quaternion(new Vector(0, 0, 1), PI / 100), scene.anchor());
  else
    scene.eye().rotate(new Quaternion(yDirection ? new Vector(0, 1, 0) : new Vector(1, 0, 0), PI / 100), scene.anchor());
}

void keyPressed() {
  if ( key == 'a')
    numSubpixels ++;
   if ( key == 's')
    numSubpixels = numSubpixels >2 ? numSubpixels-1 :  1;
  if (key == 'g')
    gridHint = !gridHint;
  if (key == 't')
    triangleHint = !triangleHint;
  if (key == 'd')
    debug = !debug;
  if (key == '+') {
    n = n < 7 ? n+1 : 2;
    frame.setScaling(width/pow( 2, n));
  }
  if (key == '-') {
    n = n >2 ? n-1 : 7;
    frame.setScaling(width/pow( 2, n));
  }
  if (key == 'r')
    randomizeTriangle();
  if (key == ' ')
    if (spinningTask.isActive())
      spinningTask.stop();
    else
      spinningTask.run(20);
  if (key == 'y')
    yDirection = !yDirection;
}

