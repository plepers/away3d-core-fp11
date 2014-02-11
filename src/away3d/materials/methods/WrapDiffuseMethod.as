package away3d.materials.methods
{
	import com.instagal.Tex;
	import com.instagal.regs.*;
	import com.instagal.ShaderChunk;
	import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.utils.ShaderRegisterCache;
	import away3d.materials.utils.ShaderRegisterElement;
	import away3d.textures.Texture2DBase;
	
	import flash.display3D.Context3DProgramType;

	use namespace arcane;

	/**
	 * WrapDiffuseMethod is an alternative to BasicDiffuseMethod in which the light is allowed to be "wrapped around" the normally dark area, to some extent.
	 * It can be used as a crude approximation to Oren-Nayar or subsurface scattering.
	 */
	public class WrapDiffuseMethod extends BasicDiffuseMethod
	{
		private var _wrapDataRegister : ShaderRegisterElement;
		private var _scatterTextureRegister : ShaderRegisterElement;
		private var _scatterTexture : Texture2DBase;
		private var _wrapFactor : Number;

		/**
		 * Creates a new WrapDiffuseMethod object.
		 * @param wrap A factor to indicate the amount by which the light is allowed to wrap
		 * @param scatterTexture A texture that contains the light colour based on the angle. This can be used to change the light colour due to subsurface scattering when dot &lt; 0
		 */
		public function WrapDiffuseMethod(wrapFactor : Number = .5, scatterTexture : Texture2DBase = null)
		{
			super();
			this.wrapFactor = wrapFactor;
			this.scatterTexture = scatterTexture;
		}


		override arcane function initConstants(vo : MethodVO) : void
		{
			super.initConstants(vo);
			vo.fragmentData[vo.secondaryFragmentConstantsIndex+2] = .5;
		}

		public function get scatterTexture() : Texture2DBase
		{
			return _scatterTexture;
		}

		public function set scatterTexture(value : Texture2DBase) : void
		{
			if (Boolean(_scatterTexture) != Boolean(value)) invalidateShaderProgram();
			_scatterTexture = value;
		}

		arcane override function cleanCompilationData() : void
		{
			super.cleanCompilationData();
			_wrapDataRegister = null;
			_scatterTextureRegister = null;
		}

		public function get wrapFactor() : Number
		{
			return _wrapFactor
		}

		public function set wrapFactor(value : Number) : void
		{
			_wrapFactor = value;
			_wrapFactor = 1/(value+1);
		}

		arcane override function getFragmentPreLightingCode(vo : MethodVO, regCache : ShaderRegisterCache) : ShaderChunk
		{
			var code : ShaderChunk = super.getFragmentPreLightingCode(vo, regCache);
			_wrapDataRegister = regCache.getFreeFragmentConstant();
			vo.secondaryFragmentConstantsIndex = _wrapDataRegister.index*4;

			if (_scatterTexture) {
				_scatterTextureRegister = regCache.getFreeTextureReg();
				if (!_useTexture)
					vo.texturesIndex = _scatterTextureRegister.index;
			}
			return code;
		}

		arcane override function getFragmentCodePerLight(vo : MethodVO, lightIndex : int, lightDirReg : ShaderRegisterElement, lightColReg : ShaderRegisterElement, regCache : ShaderRegisterCache) : ShaderChunk
		{
			var code : ShaderChunk = new ShaderChunk();
			var t : ShaderRegisterElement;

			// write in temporary if not first light, so we can add to total diffuse colour
			if (lightIndex > 0) {
				t = regCache.getFreeFragmentVectorTemp();
				regCache.addFragmentTempUsages(t, 1);
			}
			else {
				t = _totalLightColorReg;
			}
			
			var tr : uint = t.value();

			code.dp3( tr^x,lightDirReg.value() ^xyz   , _normalFragmentReg.value() ^xyz );
			code.add( tr^y,tr^x               , _wrapDataRegister.value() ^x   );
			code.mul( tr^y,tr^y               , _wrapDataRegister.value() ^y   );
			code.sat( tr^w,tr^y);
			code.mul( tr^w,tr^w               , lightDirReg.value()        ^w   );

			if (_modulateMethod != null) _modulateMethod(code, vo, t, regCache);

			if (_scatterTexture) {
				code.mul(tr ^x  ,  tr ^x  , _wrapDataRegister.value() ^z );
				code.add(tr ^x  ,  tr ^x  , tr ^x );
				code.tex(tr ^xyz,  tr ^x, _scatterTextureRegister.value() |Tex.NEAREST |Tex.CLAMP );
				code.mul(tr ^xyz,  tr ^xyz, tr ^w);
				code.mul(tr ^xyz,  tr ^xyz, lightColReg.value() ^xyz);

			}
			else {
				code.mul( tr, tr^ w, lightColReg.value() );
			}


			if (lightIndex > 0) {
				code.add(_totalLightColorReg.value() ^xyz, _totalLightColorReg.value() ^xyz, tr^xyz );
				regCache.removeFragmentTempUsage(t);
			}

			return code;
		}


		arcane override function activate(vo : MethodVO, stage3DProxy : Stage3DProxy) : void
		{
			super.activate(vo, stage3DProxy);
			var index : int = vo.secondaryFragmentConstantsIndex;
			var data : Vector.<Number> = vo.fragmentData;
			data[index] = _wrapFactor;
			data[index+1] = 1/(_wrapFactor+1);

			if (_scatterTexture) {
				index = _useTexture? vo.texturesIndex+1 : vo.texturesIndex;
				stage3DProxy.setTextureAt(index, _scatterTexture.getTextureForStage3D(stage3DProxy));
			}
		}
	}
}
