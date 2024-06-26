let colorWheel = function( pos ) {
    let r = 0;
    let g = 0;
    let b = 0;
    pos = 255 - pos;

    if ( pos < 85 ) {
        r = 255 - pos * 3;
        g = 0;
        b = pos * 3;
    } else if (pos < 170) {
        pos -= 85;
        r = 0;
        g = pos * 3;
        b = 255 - pos * 3;
    } else {
        pos -= 170;
        r = pos * 3;
        g = 255 - pos * 3;
        b = 0;
    }

    return { red: r, green: g, blue: b};
};

let iterations = 1;
for(let i = 0; i < 255 * iterations; i++) {
    for(let y = 0; y < matrix.width; y++) {
        for(let x = 0; x < matrix.height; x++) {
            let index = ((x * 255 / matrix.height) + i) & 255;
            let showColor = colorWheel( index );
            setPixelColor(showColor.red, showColor.green, showColor.blue, 0, x, y);
        }
    }
    updatePixels();
}
