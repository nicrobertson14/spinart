Canvas cvs;
VerticalSlider redCP, greenCP, blueCP, speed, strokewidth, strokepoints;
Button clear, reverb, distort, sine, saw, pulse, mute;
Object lockedObject;
int displayWidth = 1280, displayHeight = 700;

void setup() {
    size(displayWidth, displayHeight, P2D);
    background(100);
    cvs = new Canvas(0,0,460);
    redCP = new VerticalSlider(20, 40, 0, 255, "R", 0);
    greenCP = new VerticalSlider(60, 40, 0, 255, "G", 0);
    blueCP = new VerticalSlider(100, 40, 0, 255, "B", 0);
    speed = new VerticalSlider(20, 220, 0, radians(8), "Speed", radians(2.0));
    strokewidth = new VerticalSlider(60, 220, 0, 16, "Width", 5);
    strokepoints = new VerticalSlider(100, 220, 3, 10, "Points", 4);
    clear = new Button(width - 70,10,60, 30, cvs.clear, "CLEAR");

    sine = new Button(width - 70, 190, 60, 30, setSine, "SINE");
    saw = new Button(width - 70, 230, 60, 30, setSaw, "SAW");
    pulse = new Button(width - 70, 270, 60, 30, setPulse, "PULSE");

    reverb = new Button(width - 70, 450, 60, 30, toggleReverb, "REVERB");
    distort = new Button(width - 70, 490, 60, 30, toggleDistort, "DISTORT");

    mute = new Button(width - 70, 610, 60, 30, muteOsc, "MUTE");
}

void draw() { 
    background(100);
    cvs.draw();
    
    // controls
    redCP.draw();
    greenCP.draw();
    blueCP.draw();
    speed.draw();
    strokewidth.draw();
    strokepoints.draw();
    

    // color swatch
    fill(255,255,255)
    textSize(16)
    text("Stroke Preview", 200, 20)
    fill(redCP.value, greenCP.value, blueCP.value);
    polygon(200, 50, strokewidth.value, round(strokepoints.value));

    // buttons
    clear.draw();
    reverb.draw();
    distort.draw();
    sine.draw();
    saw.draw();
    pulse.draw();
    mute.rgb = muteOn ? [255,0,0] : [200,200,200];
    mute.draw();

    if (mousePressed == true) {
        if (!lockedObject) {
            if (clear.inBounds()) {
                clear.click();
            }
            else if (reverb.inBounds()) {
                reverb.click();
            }
            else if (distort.inBounds()) {
                distort.click();
            }
            else if (sine.inBounds()) {
                sine.click();
            }
            else if (saw.inBounds()) {
                saw.click();
            }
            else if (pulse.inBounds()) {
                pulse.click();
            }
            else if (mute.inBounds()) {
                mute.click();
            }
            else if (cvs.inBounds()) {
                cvs.strokes.add(new Stroke());
            }
        }
        else {
            redCP.setColor(redCP.value, 0, 0);
            greenCP.setColor(0, greenCP.value, 0);
            blueCP.setColor(0, 0, blueCP.value);
        }
    }
}

void mouseReleased() {
    lockedObject = null;
}

int constrain(int val, int minv, int maxv) {
    return min(max(val, minv), maxv);
}

void polygon(double x, double y, double radius, int npoints) {
    double angle = TWO_PI / npoints;
    beginShape();
    for (double a = 0; a < TWO_PI; a += angle) {
        double sx = x + cos(a) * radius;
        double sy = y + sin(a) * radius;
        vertex(sx, sy);
    }
    endShape(CLOSE);
}

class VerticalSlider extends UIElement {
    int min, max, offset, sliderLength = 128;
    double value;
    string label;

    VerticalSlider(int x, int y, int min, int max, string label, double defaultValue) {
        super(x, y, 30, 15);
        this.max = max;
        this.min = min;
        this.offset = max/sliderLength;
        this.label = label;
        this.value = defaultValue;
    }

    void draw() {
        if (mousePressed && (this.inBounds() || lockedObject == this)) {
            lockedObject = this;
            this.value = constrain(this.max * ((mouseY - this.y)/sliderLength), this.min, this.max);
        }
        stroke(10);
        rectMode(CORNER);

        // Slider Track
        fill(this.r, this.g, this.b);
        rect(this.x, this.y, 10, sliderLength + 10);

        // Slider Handle
        fill(255);
        rect(this.x - 10, this.y + this.value/this.offset, this.width, this.height);

        // Labels
        fill(0);
        textAlign(CENTER, CENTER);
        if (this.label == "Speed") {
            float speed = round(this.value * 100)
            text(speed, this.x + this.width/5, this.y + this.height/2 + this.value/this.offset)
        }
        else {
            text(round(this.value), this.x + this.width/5, this.y + this.height/2 + this.value/this.offset);
        }
        text(this.label, this.x + this.width/5, this.y + sliderLength + (2 * this.height));
    }

    boolean inBounds() {
        return mouseX >= this.x
            && mouseX <= (this.x + this.width)
            && mouseY >= (this.y + this.value/this.offset)
            && mouseY <= (this.y + this.value/this.offset + this.height);
    }
}

class Canvas extends UIElement {
    int angle = 0;
    ArrayList strokes = new ArrayList();

    Canvas(int x, int y, int size) {
        super(x,y,size,size);
    }

    void update() {
        translate(displayWidth/2, displayHeight/2);
        rotate(angle);
        this.angle = (this.angle + speed.value) % TWO_PI;
    }

    void draw() {
        
        pushMatrix();
        this.update();
        fill(255);
        rectMode(CENTER);
        rect(this.x, this.y, this.width, this.height);

        for (Stroke stroke : this.strokes) {
            stroke.draw();
        }
        popMatrix();
    }

    void inBounds() {
        return sqrt(sq((displayWidth/2) - mouseX) + sq((displayHeight/2) - mouseY)) < this.height/2;
    }

    void clear() {
        this.strokes.clear();
    }
}

class Stroke extends UIElement {
    double x, y, strokeWidth, strokeHeight, radius, angle;
    int points;
    float dirX, dirY;

    Stroke() {
        float dirX = mouseX - displayWidth/2;
        float dirY = mouseY - displayHeight/2;
        this.radius = sqrt(sq(dirX) + sq(dirY));
        this.angle = (TWO_PI - (1.5 * PI + atan2(dirX, dirY) + cvs.angle)) % TWO_PI;
        this.strokeWidth = this.strokeHeight = strokewidth.value;
        this.setColor(redCP.value, greenCP.value, blueCP.value);
        this.points = strokepoints.value;
        this.x = this.radius * cos(this.angle);
        this.y = this.radius * sin(this.angle);
    }

    void draw() {
        // int baseFrequency = 55;
        float frequencies = [220, 246.94, 261.63, 293.66,329.63, 349.23, 392, 440];
        float phase = ((TWO_PI + cvs.angle + this.angle) % TWO_PI);
        
        noStroke();
        fill(this.r,this.g,this.b);
        // Trigger a synth note for ~30% of strokes as they pass 3 O'Clock
        if (phase >= (PI/32) && phase <= (PI/16)) {
            if (millis() % 10 < 3){
                play(frequencies[floor((this.radius/230) * 8)]);
                this.r += 5;
            }
        }
        polygon(this.x, this.y, this.strokeWidth, round(this.points));
    }
}

class Button extends UIElement {
    Callable<T> func;
    string label;
    
    Button(int x, int y, int width, int height, Callable<T> func, string label) {
        super(x,y,width,height);
        this.func = func;
        this.label = label;
        this.rgb = [200,200,200];
    }
    void draw() {
        fill(this.rgb[0],this.rgb[1],this.rgb[2]);
        rect(this.x, this.y, this.width, this.height);
        fill(0);
        textSize(14);
        text(this.label, this.x + this.width/2, this.y + this.height/2);
    }

    void click() {
        lockedObject = this;
        this.func.call();
    }
}

class UIElement {
    int x, y, width, height, r, g, b;

    UIElement(int x, int y, int width, int height) {
        this.x = x;
        this.y = y;
        this.width = width;
        this.height = height;
        this.setColor(0,0,0);
    }

    boolean inBounds() {
        return mouseX >= this.x
            && mouseX <= (this.x + this.width)
            && mouseY >= this.y
            && mouseY <= (this.y + this.height);
    }

    void setColor(int r, int g, int b) {
        this.r = r;
        this.g = g;
        this.b = b;
    }
}