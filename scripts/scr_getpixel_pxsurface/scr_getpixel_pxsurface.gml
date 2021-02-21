/**
 * Get the pixel color on the Pixel Surface
 */
function scr_getpixel_pxsurface(xx, yy) {
	// Get the pixel buffer position
	var px = (xx + ( yy * winW) ) * 4;
	
	// Return the GM color from the rgb components
	selectedPxCol = (
			buffer_peek(pxBuffer, px, buffer_u8) + // Red
			(256* buffer_peek(pxBuffer, px+1, buffer_u8)) // Green
		) + 
		(65536* buffer_peek(pxBuffer, px+2, buffer_u8)); // Blue
}