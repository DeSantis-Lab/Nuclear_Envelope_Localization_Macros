/*Section 1: making the rois around the nucleus. It first uses thresholding to find the nuclear perimeter.
It then deletes any nuclei for which the kash signal is under the threshold we set*/
Sun_threshold = 200; //Sun_threshold is the intensity value of sun1 that is necessary for us to consider that nucleus
Kash_cell_threshold = 220; //threshold of total kash in the cell
dir2 = getInfo("image.directory");
title = getTitle(); //this gets the name of the file so we can parse it

run("Split Channels"); //splits channels into c1- nuclei, c2-dynein, c3- sun1 and c4- kash
selectWindow("C1-" + title); // selects nuclei channel

setAutoThreshold("Default dark");
//run("Threshold...");
run("Convert to Mask");
//above runs thresholding on nuclei channel

run("Analyze Particles...", "size=5.00-Infinity display exclude add");
//Uses nuclei thresholds to define rois



nROIs = roiManager("count"); //Gets number of nuclei to iterate over

run("Clear Results");
selectWindow("C3-"+ title);
roiManager("Deselect");
roiManager("Measure");
//the above gets the measurement in the sun channel for each nucleus, which we use below to only make rois for cells with enough kash expression

for (i = 0; i < nROIs; i++) {

Sun_int = getResult("Mean", i); //sets sun intensity to the appropriate nucleus

//If sun expression is below the threshold no band roi is created, if it is above than the band is added to the roi
if (Sun_int < Sun_threshold) {
roiManager("Select", 0);
roiManager("Delete");

}

else{
roiManager("Select", 0);
roiManager("Add");
roiManager("Select", 0);
roiManager("Delete");
}
}

//Next we want to delete cells that are not fully in the field of view and save the nuclear roi
selectWindow("C4-" + title);
waitForUser("Delete any ROIs for cells that are not completely in the field of view or have no kash expression, click OK when done");

nNuclei = roiManager("count"); //Gets number of cells to trace based on number of nuclei

if (nNuclei > 0){
roiManager("Deselect");
roiManager("Save", dir2 + title + "nuclei_ROIs.roi.zip"); //saves rois for just the nuclei
run("Clear Results");
}

else {
roiManager("reset");
run("Clear Results");
run("Close All");
exit("There are no nuclei with enough Sun expression");
}
/* Section 2: To start we expand the nuclear ROIs since we need that for making the cytoplasmic rois.
 * Next we ask the user to trace the cell exterior. 
 * It is absolutely critical they do this in the same order as the nuclear rois. 
 */


//Tracing the cell exterior:
setTool("polygon");
selectWindow("C2-" + title);
for (i = 0; i < nNuclei; i++) {
cellNumber=i+1;	
waitForUser("Draw the cell boundary by hand for cell "+cellNumber+", click OK when done");
roiManager("Add");
}

//Saving the cell exterior rois:
cell_ext=newArray();
for (i=0; i<nNuclei; i++) {
	cell_i = nNuclei + i;
	cell_ext= Array.concat(cell_ext,cell_i);
}
roiManager("select",cell_ext);
roiManager("Save selected", dir2 + title + "cell-exterior_ROIs.roi.zip"); //saves rois for just the cell exterior


//Next we only want to take cells with enough total kash expression. we will also rewrite the nuclear and cell boundary rois

run("Clear Results");
roiManager("reset");
roiManager("open", dir2 + title + "cell-exterior_ROIs.roi.zip");
selectWindow("C4-"+ title);
roiManager("Deselect");
roiManager("Measure");
//the above gets the measurement in the kash channel for each cell, which we use below to only make rois for cells with enough kash expression
lowKash=newArray(); //makes an array to indicate which kash cells need to be deleted

for (i = 0; i < nNuclei; i++) {

Kash_int = getResult("Mean", i); //sets kash intensity to the appropriate cell
//If kash expression is below the threshold no band roi is created, if it is above than the band is added to the roi

if (Kash_int < Kash_cell_threshold) {
	lowKash = Array.concat(lowKash,i);
}

else{
}
}
run("Clear Results");

if (lowKash.length > 0){
roiManager("select",lowKash);
roiManager("delete");
nCells = roiManager("count");
	if (nCells > 0){
	roiManager("Save", dir2 + title + "cell-exterior_ROIs.roi.zip"); //saves rois for just the cell exterior
	roiManager("reset");
	roiManager("open", dir2 + title + "nuclei_ROIs.roi.zip");
	roiManager("select",lowKash);
	roiManager("delete");
	roiManager("Save", dir2 + title + "nuclei_ROIs.roi.zip"); //resaves nuclear rois for only those with enough kash expression
	}
	else{
		roiManager("reset");
		run("Clear Results");
		run("Close All");
		exit("There are no cells with enough Kash expression");
	}
}
else{
	nCells = nNuclei;
	roiManager("reset");
	roiManager("open", dir2 + title + "nuclei_ROIs.roi.zip");
	}

//Expand the nuclear rois
for (i=0; i<nCells; i++) {
	roiManager("select",0);
	run("Enlarge...", "enlarge=1");
	roiManager("Add");
	roiManager("select",0);
	roiManager("delete");
}

//Make and save the cytoplasm rois.
roiManager("open", dir2 + title + "cell-exterior_ROIs.roi.zip");
cyto=newArray();
for (i=0; i<nCells; i++) {

	roiManager("select", newArray(i,nCells+i));
	roiManager("XOR");
	roiManager("Add");
	cyto_num = nCells + nCells + i;
	cyto= Array.concat(cyto,cyto_num);	
}
selectWindow("C2-" + title);
roiManager("select",cyto);
roiManager("Save selected", dir2 + title + "cytoplasm_ROIs.roi.zip"); //saves rois for just the cell exterior
roiManager("measure");
saveAs("results",dir2 + title + "_dynein-cyto-intensity.txt");
run("Clear Results");

selectWindow("C4-" + title);
roiManager("select",cyto);
roiManager("measure");
saveAs("results",dir2 + title + "_kash-cyto-intensity.txt");
run("Clear Results");

//reset ROI, recall nuclei roi and make the band rois around nuclei and then measure the dynein channel

roiManager("reset");
open(dir2 + title + "nuclei_ROIs.roi.zip");
nROIs = roiManager("count"); //Gets number of nuclei to iterate over

for (i=0; i < nROIs; i++) {
roiManager("select", 0);	
run("Enlarge...", "enlarge=-1");
run("Make Band...", "band=2");
roiManager("Add");	
roiManager("select", 0);
roiManager("Delete");
}

selectWindow("C2-" + title);
roiManager("Save", dir2 + title + "nuclear_band_ROIs.roi.zip"); //saves rois for just the cell exterior
roiManager("measure");
saveAs("results",dir2 + title + "_dynein-nuclei-intensity.txt");
run("Clear Results");

selectWindow("C4-" + title);
roiManager("measure");
saveAs("results",dir2 + title + "_kash-nuclei-intensity.txt");

roiManager("reset");
run("Clear Results");
run("Close All");
