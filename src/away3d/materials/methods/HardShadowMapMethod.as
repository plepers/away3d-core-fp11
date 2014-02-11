package away3d.materials.methods
{
	import com.instagal.regs.*;
	import com.instagal.Tex;
	import com.instagal.ShaderChunk;
	import away3d.arcane;
	import away3d.lights.LightBase;
	import away3d.materials.utils.ShaderRegisterCache;
	import away3d.materials.utils.ShaderRegisterElement;

	use namespace arcane;

	public class HardShadowMapMethod extends ShadowMapMethodBase
	{
		/**
		 * Creates a new HardShadowMapMethod object.
		 */
		public function HardShadowMapMethod(castingLight : LightBase)
		{
			super(castingLight);
		}

		/**
		 * @inheritDoc
		 */
		override protected function getPlanarFragmentCode(vo : MethodVO, regCache : ShaderRegisterCache, targetReg : ShaderRegisterElement) : ShaderChunk
		{
			var depthMapRegister : ShaderRegisterElement = regCache.getFreeTextureReg();
			var decReg : ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var epsReg : ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var depthCol : ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
			var code : ShaderChunk = new ShaderChunk();

			vo.fragmentConstantsIndex = decReg.index*4;
			vo.texturesIndex = depthMapRegister.index;
			
			var dcl : uint = depthCol.value();
			var tgr : uint = targetReg.value();
			var dcr : uint = _depthMapCoordReg.value();
			var dmr : uint = depthMapRegister.value();
			var drg : uint = decReg.value();
			var eps : uint = epsReg.value();


			code.tex( dcl   , dcr   , dmr | Tex.NEAREST | Tex.CLAMP );
			code.dp4( dcl ^z, dcl   , drg);
			code.add( tgr ^w, dcr ^z, eps ^x ); // offset by epsilon
			code.slt( tgr ^w, tgr ^w, dcl ^z );   // 0 if in shadow

			return code;
		}

		override protected function getPointFragmentCode(vo : MethodVO, regCache : ShaderRegisterCache, targetReg : ShaderRegisterElement) : ShaderChunk
		{
			var depthMapRegister : ShaderRegisterElement = regCache.getFreeTextureReg();
			var decReg : ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var epsReg : ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var posReg : ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var depthSampleCol : ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
			regCache.addFragmentTempUsages(depthSampleCol, 1);
			var lightDir : ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
			var code : ShaderChunk = new ShaderChunk();


			vo.fragmentConstantsIndex = decReg.index*4;
			vo.texturesIndex = depthMapRegister.index;
			
			var tgr : uint = targetReg.value();
			var dmr : uint = depthMapRegister.value();
			var drg : uint = decReg.value();
			var ldr : uint = lightDir.value();
			var psr : uint = posReg.value();
			var gpr : uint = _globalPosReg.value();
			var dsc : uint = depthSampleCol.value();
			var eps : uint = epsReg.value();

			code.sub( ldr     , gpr        ,  psr   );
			code.dp3( ldr ^w  , ldr ^xyz   ,  ldr   ^xyz);
			code.mul( ldr ^w  , ldr ^w     ,  psr   ^w);
			code.nrm( ldr ^xyz, ldr ^xyz);
			code.tex( dsc     , ldr        ,  dmr  | Tex.NEAREST | Tex.CLAMP ); 
			code.dp4( dsc ^z  , dsc        ,  drg);
			code.add( tgr ^w  , ldr ^w     ,  eps   ^x);    // offset by epsilon
			code.slt( tgr ^w  , tgr ^w     ,  dsc   ^z);   // 0 if in shadow

			regCache.removeFragmentTempUsage(depthSampleCol);

			return code;
		}
	}
}