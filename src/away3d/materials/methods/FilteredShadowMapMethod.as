package away3d.materials.methods
{
	import com.instagal.Tex;
	import com.instagal.regs.*;
	import com.instagal.ShaderChunk;
	import away3d.arcane;
	import away3d.lights.DirectionalLight;
	import away3d.materials.utils.ShaderRegisterCache;
	import away3d.materials.utils.ShaderRegisterElement;

	use namespace arcane;

	public class FilteredShadowMapMethod extends ShadowMapMethodBase
	{
		/**
		 * Creates a new BasicDiffuseMethod object.
		 *
		 * @param castingLight The light casting the shadow
		 */
		public function FilteredShadowMapMethod(castingLight : DirectionalLight)
		{
			super(castingLight);
		}

		override arcane function initConstants(vo : MethodVO) : void
		{
			super.initConstants(vo);

			var fragmentData : Vector.<Number> = vo.fragmentData;
			var index : int = vo.fragmentConstantsIndex;
			fragmentData[index+8] = .5;
			fragmentData[index+9] = castingLight.shadowMapper.depthMapSize;
			fragmentData[index+10] = 1/castingLight.shadowMapper.depthMapSize;
		}

		/**
		 * @inheritDoc
		 */
		override protected function getPlanarFragmentCode(vo : MethodVO, regCache : ShaderRegisterCache, targetReg : ShaderRegisterElement) : ShaderChunk
		{
			var depthMapRegister : ShaderRegisterElement = regCache.getFreeTextureReg();
			var decReg : ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var dataReg : ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var customDataReg : ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var depthCol : ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
			var uvReg : ShaderRegisterElement;
			var code : ShaderChunk = new ShaderChunk();
			vo.fragmentConstantsIndex = decReg.index*4;
			
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
			regCache.addFragmentTempUsages(uvReg, 1);

			code.mov( uvr		, dcr);
			code.tex( dcl		, dcr		, dmr |Tex.NEAREST |Tex.CLAMP);
			code.dp4( dcl^z		, dcl		, drg );
			code.sub( dcl^z		, dcl^z		, ddr ^x); 	// offset by epsilon
			code.slt( uvr^z		, dcr^z		, dcl ^z);   // 0 if in shadow
			code.add( uvr^x		, dcr^x		, cdr ^z); 	// (1, 0)
			code.tex( dcl		, uvr		, dmr |Tex.NEAREST |Tex.CLAMP);
			code.dp4( dcl^z		, dcl		, drg );
			code.sub( dcl^z		, dcl^z		, ddr ^x);	// offset by epsilon
			code.slt( uvr^w		, dcr^z		, dcl ^z);   // 0 if in shadow
			code.mul( dcl^x		, dcr^x		, cdr ^y);
			code.frc( dcl^x		, dcl^x);
			code.sub( uvr^w		, uvr^w		, uvr ^z);
			code.mul( uvr^w		, uvr^w		, dcl ^x);
			code.add( tgr^w		, uvr^z		, uvr ^w);
			code.mov( uvr^x		, dcr^x);
			code.add( uvr^y		, dcr^y		, cdr ^z);	// (0, 1)
			code.tex( dcl		, uvr		, dmr |Tex.NEAREST |Tex.CLAMP);
			code.dp4( dcl^z		, dcl		, drg );
			code.sub( dcl^z		, dcl^z		, ddr ^x);	// offset by epsilon
			code.slt( uvr^z		, dcr^z		, dcl ^z);   // 0 if in shadow
			code.add( uvr^x		, dcr^x		, cdr ^z);	// (1, 1)
			code.tex( dcl		, uvr		, dmr  |Tex.NEAREST |Tex.CLAMP);
			code.dp4( dcl^z		, dcl		, drg );
			code.sub( dcl^z		, dcl^z		, ddr ^x);	// offset by epsilon
			code.slt( uvr^w		, dcr^z		, dcl ^z);   // 0 if in shadow
			code.mul( dcl^x		, dcr^x		, cdr ^y);
			code.frc( dcl^x		, dcl^x	);
			code.sub( uvr^w		, uvr^w		, uvr ^z);
			code.mul( uvr^w		, uvr^w		, dcl ^x);
			code.add( uvr^w		, uvr^z		, uvr ^w);
			code.mul( dcl^x		, dcr^y		, cdr ^y);
			code.frc( dcl^x		, dcl^x		);
			code.sub( uvr^w		, uvr^w		, tgr ^w);
			code.mul( uvr^w		, uvr^w		, dcl ^x);
			code.add( tgr^w		, tgr^w		, uvr ^w);

			regCache.removeFragmentTempUsage(depthCol);
			regCache.removeFragmentTempUsage(uvReg);

			vo.texturesIndex = depthMapRegister.index;

			return code;
		}
	}
}