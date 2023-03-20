//use this to convert hue-saturation-value colors to red-green-blue colors for use with OpenSCAD's color() module
//Rainbows are much easier to  make now!

/****************************************************/
/*						How to Use					*/
/****************************************************/

//use the hsvToRGB function to convert hsv colors to rgb colors
//it takes 4 parameters:
//	h is a value from 0.0 to 1.0 and represents hue which is the type of color (red, green, blue, orange, yellow, etc)
//		0.0 is red
//		0.33 is green
//		0.66 is blue
//	s is a value from 0.0 to 1.0 and controls saturation which is how 'rich' the color is
//	v is a value from 0.0 to 1.0 and controls the value of the color which is how bright the color is
//	a is a value from 0.0 to 1.0 and controls how transparent the color is

//parameters will default to 1.0 if they are not set

/****************************************************/
/*						Example						*/
/****************************************************/

//changing hue
for(i = [0:10])
{
	color(hsvToRGB(1 / 10 * i, 1, 1, 1))
		translate([0,0,1 * i])
			cube([11 - i,11 - i,1], center = true);
}

//changing saturation
translate([0,15,0])
for(i = [0:10])
{
	color(hsvToRGB(1, 1 / 10 * i, 1, 1))
		translate([0,0,1 * i])
			cube([11 - i,11 - i,1], center = true);
}

//changing value
translate([15,0,0])
for(i = [0:10])
{
	color(hsvToRGB(1, 1, 1 / 10 * i, 1))
		translate([0,0,1 * i])
			cube([11 - i,11 - i,1], center = true);
}

//changing alpha
translate([15,15,0])
for(i = [0:10])
{
	color(hsvToRGB(1, 1, 1, 1 / 10 * i))
		translate([0,0,1 * i])
			cube([11 - i,11 - i,1], center = true);
}


/****************************************************/
/*				Modules and Functions				*/
/****************************************************/

function hsvToRGB(h = 1, s = 1, v = 1, a = 1) =	[
													hsvToPreRGB(h, s, v, a)[0] + hsvToMin(h, s, v, a),
													hsvToPreRGB(h, s, v, a)[1] + hsvToMin(h, s, v, a),
													hsvToPreRGB(h, s, v, a)[2] + hsvToMin(h, s, v, a),
													a
												];


function hsvToChroma(h, s, v, a) = s * v;

function hsvToHdash(h, s, v, a) = h * 360 / 60;

function hsvToX(h, s, v, a) = hsvToChroma(h, s, v, a) * (1.0 - abs((hsvToHdash(h, s, v, a) % 2.0) - 1.0));

function hsvToMin(h, s, v, a) = v - hsvToChroma(h, s, v, a);

function hsvToPreRGB(h, s, v, a) = 	hsvToHdash(h, s, v, a) < 1.0 ? [hsvToChroma(h, s, v, a), hsvToX(h, s, v, a), 0, a] :
									hsvToHdash(h, s, v, a) < 2.0 ? [hsvToX(h, s, v, a), hsvToChroma(h, s, v, a), 0, a] :
									hsvToHdash(h, s, v, a) < 3.0 ? [0, hsvToChroma(h, s, v, a), hsvToX(h, s, v, a), a] :
									hsvToHdash(h, s, v, a) < 4.0 ? [0, hsvToX(h, s, v, a), hsvToChroma(h, s, v, a), a] :
									hsvToHdash(h, s, v, a) < 5.0 ? [hsvToX(h, s, v, a), 0, hsvToChroma(h, s, v, a), a] :
									[hsvToChroma(h, s, v, a), 0, hsvToX(h, s, v, a), a];

