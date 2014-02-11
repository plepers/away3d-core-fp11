package away3d.materials.methods {

	import com.instagal.ShaderChunk;
	import com.instagal.regs.*;
	import com.instagal.Tex;
	import away3d.arcane;
	import away3d.lights.DirectionalLight;
	import away3d.materials.utils.ShaderRegisterCache;
	import away3d.materials.utils.ShaderRegisterElement;

	use namespace arcane;
	public class SoftShadowMapMethod extends ShadowMapMethodBase {

		/**
		 * Creates a new BasicDiffuseMethod object.
		 */
		public function SoftShadowMapMethod(castingLight : DirectionalLight) {
			super(castingLight);
		}

		override arcane function initConstants(vo : MethodVO) : void {
			super.initConstants(vo);

			var fragmentData : Vector.<Number> = vo.fragmentData;
			var index : int = vo.fragmentConstantsIndex;
			fragmentData[index + 8] = 1 / 9;
			fragmentData[index + 9] = 1 / castingLight.shadowMapper.depthMapSize;
			fragmentData[index + 10] = 0;
		}

		/**
		 * @inheritDoc
		 */
		override protected function getPlanarFragmentCode(vo : MethodVO, regCache : ShaderRegisterCache, targetReg : ShaderRegisterElement) : ShaderChunk {
			var depthMapRegister : ShaderRegisterElement = regCache.getFreeTextureReg();
			var decReg : ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var dataReg : ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var customDataReg : ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var depthCol : ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
			var uvReg : ShaderRegisterElement;
			var code : ShaderChunk = new ShaderChunk();
			vo.fragmentConstantsIndex = decReg.index * 4;

			var uvr : uint = uvReg.value();
			var dcl : uint = depthCol.value();
			var tgr : uint = targetReg.value();
			var dcr : uint = _depthMapCoordReg.value();
			var dmr : uint = depthMapRegister.value();
			var cdr : uint = customDataReg.value();
			var ddr : uint = dataReg.value();
			var drg : uint = decReg.value();

			regCache.addFragmentTempUsages(depthCol, 1);

			uvReg = regCache.getFreeFragmentVectorTemp();

			code.mov( uvr ,   dcr );
			code.tex( dcl ,   dcr ,    dmr | Tex.D2 |Tex.NEAREST|Tex.CLAMP ); 
			code.add( uvr ^z, dcr ^z,  ddr ^x);     // offset by epsilon 
			code.dp4( dcl ^z, dcl ,    drg ); 
			code.slt( tgr ^w, uvr ^z,  dcl ^z);    // 0 if in shadow 
			code.sub( uvr ^x, dcr ^x,  cdr ^y); 	// (-1, 0) 
			code.tex( dcl ,   uvr ,    dmr | Tex.D2 |Tex.NEAREST|Tex.CLAMP ); 
			code.dp4( dcl ^z, dcl ,    drg ); 
			code.slt( uvr ^w, uvr ^z,  dcl ^z);    // 0 if in shadow 
			code.add( tgr ^w, tgr ^w,  uvr ^w); 
			code.add( uvr ^x, dcr ^x,  cdr ^y); 		// (1, 0) 
			code.tex( dcl ,   uvr ,    dmr | Tex.D2 |Tex.NEAREST|Tex.CLAMP ); 
			code.dp4( dcl ^z, dcl ,    drg ); 
			code.slt( uvr ^w, uvr ^z,  dcl ^z);    // 0 if in shadow 
			code.add( tgr ^w, tgr ^w,  uvr ^w); 
			code.mov( uvr ^x, dcr ^x); 
			code.sub( uvr ^y, dcr ^y,  cdr ^y); 	// (0, -1) 
			code.tex( dcl ,   uvr ,    dmr | Tex.D2 |Tex.NEAREST|Tex.CLAMP ); 
			code.dp4( dcl ^z, dcl ,    drg ); 
			code.slt( uvr ^w, uvr ^z,  dcl ^z);    // 0 if in shadow 
			code.add( tgr ^w, tgr ^w,  uvr ^w); 
			code.add( uvr ^y, dcr ^y,  cdr ^y);	// (0, 1) 
			code.tex( dcl ,   uvr ,    dmr | Tex.D2 |Tex.NEAREST|Tex.CLAMP ); 
			code.dp4( dcl ^z, dcl ,    drg ); 
			code.slt( uvr ^w, uvr ^z,  dcl ^z);  // 0 if in shadow 
			code.add( tgr ^w, tgr ^w,  uvr ^w);
			code.sub( uvr ^xy,dcr ^xy, cdr ^y ); // (0, -1) 
			code.tex( dcl ,   uvr ,    dmr  | Tex.D2 |Tex.NEAREST|Tex.CLAMP );  
			code.dp4( dcl ^z, dcl ,    drg ); 
			code.slt( uvr ^w, uvr ^z,  dcl ^z);   // 0 if in shadow// 
			code.add( tgr ^w, tgr ^w,  uvr ^w); 
			code.add( uvr ^y, dcr ^y,  cdr ^y);	// (-1, 1) 
			code.tex( dcl ,   uvr ,    dmr  | Tex.D2 |Tex.NEAREST|Tex.CLAMP );  
			code.dp4( dcl ^z, dcl ,    drg ); 
			code.slt( uvr ^w, uvr ^z,  dcl ^z);   // 0 if in shadow 
			code.add( tgr ^w, tgr ^w,  uvr ^w); 
			code.add( uvr ^xy,dcr ^xy, cdr ^y );  // (1, 1) 
			code.tex( dcl ,   uvr ,    dmr  | Tex.D2 |Tex.NEAREST|Tex.CLAMP );  
			code.dp4( dcl ^z, dcl ,    drg ); 
			code.slt( uvr ^w, uvr ^z,  dcl ^z);   // 0 if in shadow 
			code.add( tgr ^w, tgr ^w,  uvr ^w); 
			code.sub( uvr ^y, dcr ^y,  cdr ^y);	// (1, -1) 
			code.tex( dcl ,   uvr ,    dmr  | Tex.D2 |Tex.NEAREST|Tex.CLAMP );  
			code.dp4( dcl ^z, dcl ,    drg ); 
			code.slt( uvr ^w, uvr ^z,  dcl ^z);   // 0 if in shadow 
			code.add( tgr ^w, tgr ^w,  uvr ^w );
			//

			regCache.removeFragmentTempUsage(depthCol);
			code.mul( tgr ^w, tgr ^w,  cdr ^x );
			// average

			vo.texturesIndex = depthMapRegister.index;

			return code;
		}
	}
}