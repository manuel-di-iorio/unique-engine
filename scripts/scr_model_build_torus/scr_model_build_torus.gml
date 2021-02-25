function scr_model_build_torus(vbuff, color) {
    var _r1 = 30;  //middle radius of torus
    var _r2 = .3;   //thickness of ring
    var _si = 360/60; //step size for i
    var _sj = 360/60; //step size for j
	
    for(var i = 0; i < 360; i += _si) {
        for(var j = 0; j < 360; j += _sj) {
            scr_model_build_torus_vertex(vbuff, i+_si, j,     _r1,_r2, color);  //triangle 1, vertex 1
            scr_model_build_torus_vertex(vbuff, i,     j,     _r1,_r2, color);
            scr_model_build_torus_vertex(vbuff, i,     j+_sj, _r1,_r2, color);
            scr_model_build_torus_vertex(vbuff, i+_si, j,     _r1,_r2, color);  //triangle 2, vertex 1
            scr_model_build_torus_vertex(vbuff, i,     j+_sj, _r1,_r2, color);
            scr_model_build_torus_vertex(vbuff, i+_si, j+_sj, _r1,_r2, color);
        }
    }  
}