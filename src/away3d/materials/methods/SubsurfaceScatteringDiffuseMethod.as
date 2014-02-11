package away3d.materials.methods
{
	import com.instagal.Tex;
	import com.instagal.regs.*;
	import com.instagal.ShaderChunk;
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.methods.MethodVO;
	import away3d.materials.passes.MaterialPassBase;
	import away3d.materials.passes.SingleObjectDepthPass;
	import away3d.materials.utils.ShaderRegisterCache;
	import away3d.materials.utils.ShaderRegisterElement;

	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.textures.Texture;
	import flash.geom.Matrix3D;

	use namespace arcane;

	/**
	 * SubsurfaceScatteringDiffuseMethod provides a depth map-based diffuse shading method that mimics the scattering of
	 * light inside translucent surfaces. It allows light to shine through an object and to soften the diffuse shading.
	 * It can be used for candle wax, ice, skin, ...
	 */
	public class SubsurfaceScatteringDiffuseMethod extends CompositeDiffuseMethod
	{
		private var _depthPass : SingleObjectDepthPass;
		private var _lightProjVarying : ShaderRegisterElement;
		private var _propReg : ShaderRegisterElement;
		private var _scattering : Number;
		private var _translucency : Number = 1;
		private var _lightIndex : int;
		private var _totalScatterColorReg : ShaderRegisterElement;
		private var _lightColorReg : ShaderRegisterElement;
		private var _scatterColor : uint = 0xffffff;
		private var _colorReg : ShaderRegisterElement;
        private var _decReg : ShaderRegisterElement;
		private var _scatterR : Number = 1.0;
		private var _scatterG : Number = 1.0;
		private var _scatterB : Number = 1.0;

		/**
		 * Creates a new SubsurfaceScatteringDiffuseMethod object.
		 * @param depthMapSize The size of the depth map used.
		 * @param depthMapOffset The amount by which the rendered object will be inflated, to prevent depth map rounding errors.
		 */
		public function SubsurfaceScatteringDiffuseMethod(depthMapSize : int = 512, depthMapOffset : Number = 15)
		{
			super(scatterLight);
			_passes = new Vector.<MaterialPassBase>();
			_depthPass = new SingleObjectDepthPass(depthMapSize, depthMapOffset);
			_passes.push(_depthPass);
			_scattering = 0.2;
			_translucency = 1;
		}

		override arcane function initConstants(vo : MethodVO) : void
		{
			super.initConstants(vo);
			var data : Vector.<Number> = vo.vertexData;
			var index : int = vo.secondaryVertexConstantsIndex;
			data[index] = .5;
			data[index+1] = -.5;
			data[index+2] = 0;
			data[index+3] = 1;

			data = vo.fragmentData;
			index = vo.secondaryFragmentConstantsIndex;
			data[index+3] = 1.0;
			data[index+4] = 1.0;
			data[index+5] = 1/255;
			data[index+6] = 1/65025;
			data[index+7] = 1/16581375;
			data[index+10] = .5;
			data[index+11] = -.1;
		}

		arcane override function cleanCompilationData() : void
		{
			super.cleanCompilationData();

			_lightProjVarying = null;
			_propReg = null;
			_totalScatterColorReg = null;
			_lightColorReg = null;
			_colorReg = null;
			_decReg = null;
		}

		/**
		 * The amount by which the light scatters. It can be used to set the translucent surface's thickness. Use low
		 * values for skin.
		 */
		public function get scattering() : Number
		{
			return _scattering;
		}

		public function set scattering(value : Number) : void
		{
			_scattering = value;
		}

		/**
		 * The translucency of the object.
		 */
		public function get translucency() : Number
		{
			return _translucency;
		}

		public function set translucency(value : Number) : void
		{
			_translucency = value;
		}

		/**
		 * The colour the light becomes inside the object.
		 */
		public function get scatterColor() : uint
		{
			return _scatterColor;
		}

		public function set scatterColor(scatterColor : uint) : void
		{
			_scatterColor = scatterColor;
			_scatterR = ((scatterColor >> 16) & 0xff) / 0xff;
			_scatterG = ((scatterColor >> 8) & 0xff) / 0xff;
			_scatterB = (scatterColor & 0xff) / 0xff;
		}

		/**
		 * @inheritDoc
		 */
		arcane override function reset() : void
		{
			_lightIndex = 0;
			super.reset();
		}


		/**
		 * @inheritDoc
		 */
		arcane override function getVertexCode(vo : MethodVO, regCache : ShaderRegisterCache) : ShaderChunk
		{
			var code : ShaderChunk = super.getVertexCode(vo, regCache);
			var lightProjection : ShaderRegisterElement;
			var toTexRegister : ShaderRegisterElement;
			var temp : ShaderRegisterElement = regCache.getFreeVertexVectorTemp();

			toTexRegister = regCache.getFreeVertexConstant();
			vo.secondaryVertexConstantsIndex = (toTexRegister.index - vo.vertexConstantsOffset)*4;

			_lightProjVarying = regCache.getFreeVarying();
			lightProjection = regCache.getFreeVertexConstant();
			regCache.getFreeVertexConstant();
			regCache.getFreeVertexConstant();
			regCache.getFreeVertexConstant();
			
			var tmp : uint = temp.value();
			var ttr : uint = toTexRegister.value();
			var lpj : uint = lightProjection.value();
			var lpv : uint = _lightProjVarying.value();

			code.m44(  tmp , t0, lpj );
			code.rcp(  tmp ^w,    tmp^w);
			code.mul(  tmp ^xyz,  tmp^xyz, tmp^w);
			code.mul(  tmp ^xy,   tmp^xy,  ttr^xy);
			code.add(  tmp ^xy,   tmp^xy,  ttr^x);
			code.mov(  lpv ^xyz,  tmp^xyz);
			code.mov(  lpv ^w, a0^w );

			return code;
		}

		/**
		 * @inheritDoc
		 */
		arcane override function getFragmentPreLightingCode(vo : MethodVO, regCache : ShaderRegisterCache) : ShaderChunk
		{
			_totalScatterColorReg = regCache.getFreeFragmentVectorTemp();
			_colorReg = regCache.getFreeFragmentConstant();
            _decReg = regCache.getFreeFragmentConstant();
			_propReg = regCache.getFreeFragmentConstant();
			vo.secondaryFragmentConstantsIndex = _colorReg.index*4;

			regCache.addFragmentTempUsages(_totalScatterColorReg, 1);
			return super.getFragmentPreLightingCode(vo, regCache);
		}

		/**
		 * @inheritDoc
		 */
		arcane override function getFragmentCodePerLight(vo : MethodVO, lightIndex : int, lightDirReg : ShaderRegisterElement, lightColReg : ShaderRegisterElement, regCache : ShaderRegisterCache) : ShaderChunk
		{
			_lightColorReg = lightColReg;
			_lightIndex = lightIndex;
			return super.getFragmentCodePerLight(vo, lightIndex, lightDirReg, lightColReg, regCache);
		}

		/**
		 * @inheritDoc
		 */
		arcane override function getFragmentPostLightingCode(vo : MethodVO, regCache : ShaderRegisterCache, targetReg : ShaderRegisterElement) : ShaderChunk
		{
			var code : ShaderChunk = super.getFragmentPostLightingCode(vo, regCache, targetReg);
			code.add( targetReg.value() ^xyz, targetReg.value() ^xyz, _totalScatterColorReg.value() ^xyz );
			regCache.removeFragmentTempUsage(_totalScatterColorReg);
			return code;
		}

		/**
		 * @inheritDoc
		 */
		arcane override function activate(vo : MethodVO, stage3DProxy : Stage3DProxy) : void
		{
			super.activate(vo, stage3DProxy);

			var index : int = vo.secondaryFragmentConstantsIndex;
			var data : Vector.<Number> = vo.fragmentData;
			data[index] = _scatterR;
			data[index+1] = _scatterG;
			data[index+2] = _scatterB;
			data[index+8] = _scattering;
			data[index+9] = _translucency;
		}

		arcane override function setRenderState(vo : MethodVO, renderable : IRenderable, stage3DProxy : Stage3DProxy, camera : Camera3D) : void
		{
			var depthMaps : Vector.<Texture> = _depthPass.getDepthMaps(renderable, stage3DProxy);
			var projections : Vector.<Matrix3D> = _depthPass.getProjections(renderable);

			stage3DProxy.setTextureAt(vo.secondaryTexturesIndex, depthMaps[0]);
			projections[0].copyRawDataTo(vo.vertexData, vo.secondaryVertexConstantsIndex+4, true);
		}

		/**
		 * Generates the code for this method
		 */
		private function scatterLight(vo : MethodVO, targetReg : ShaderRegisterElement, regCache : ShaderRegisterCache) : ShaderChunk
		{
			var depthReg : ShaderRegisterElement = regCache.getFreeTextureReg();
			var projReg : ShaderRegisterElement = _lightProjVarying;

			// only scatter first light
			if (_lightIndex > 0) return null;

			var code : ShaderChunk = new ShaderChunk();

			vo.secondaryTexturesIndex = depthReg.index;
			
			var tsr : uint = _totalScatterColorReg.value();
			var pjr : uint = projReg.value();
			var ppr : uint = _propReg.value();
			var der : uint = depthReg.value();
			var tgr : uint = targetReg.value();
			var clr : uint = _colorReg.value();
			var lcr : uint = _lightColorReg.value();
			var dcr : uint = _decReg.value();
			

			code.tex( tsr ,      pjr ,      der |Tex.NEAREST|Tex.CLAMP );
			code.dp4( tsr ^z,    tsr ,      dcr );
			code.sub( tsr ^w,    pjr ^z,    tsr^z); 
			code.sub( tsr ^w,    ppr ^x,    tsr^w); 
			code.mul( tsr ^w,    ppr ^y,    tsr^w); 
			code.sat( tsr ^w,    tsr ^w); 
			code.neg( tgr ^y,    tgr ^x); 
			code.mul( tgr ^y,    tgr ^y,    ppr^z); 
			code.add( tgr ^y,    tgr ^y,    ppr^z); 
			code.mul( tsr ^w,    tsr ^w,    tgr^y); 
			code.sub( tsr ^y,    clr ^w,    tsr^w); 
			code.mul( tgr ^w,    tgr ^w,    tsr^y); 
			code.mul( tsr ^xyz,  lcr ^xyz,  tsr^w); 
			code.mul( tsr ^xyz,  tsr ^xyz,  clr^xyz); 

			return code;
		}
	}
}