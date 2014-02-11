package away3d.materials.methods
{
	import com.instagal.regs.*;
	import com.instagal.Tex;
	import com.instagal.ShaderChunk;
	import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.methods.MethodVO;
	import away3d.materials.utils.ShaderRegisterCache;
	import away3d.materials.utils.ShaderRegisterElement;
	import away3d.textures.CubeTextureBase;

	use namespace arcane;

	/**
	 * EnvMapDiffuseMethod provides a diffuse shading method that uses a diffuse irradiance environment map to
	 * approximate global lighting rather than lights.
	 */
	public class EnvMapAmbientMethod extends BasicAmbientMethod
	{
		private var _cubeTexture : CubeTextureBase;

		/**
		 * Creates a new EnvMapDiffuseMethod object.
		 * @param envMap The cube environment map to use for the diffuse lighting.
		 */
		public function EnvMapAmbientMethod(envMap : CubeTextureBase)
		{
			super();
			_cubeTexture = envMap;
		}

		override arcane function initVO(vo : MethodVO) : void
		{
			super.initVO(vo);
			vo.needsNormals = true;
		}

		/**
		 * @inheritDoc
		 */
		override public function dispose() : void
		{
		}

		/**
		 * The cube environment map to use for the diffuse lighting.
		 */
		public function get envMap() : CubeTextureBase
		{
			return _cubeTexture;
		}

		public function set envMap(value : CubeTextureBase) : void
		{
			_cubeTexture = value;
		}

		/**
		 * @inheritDoc
		 */
		arcane override function activate(vo : MethodVO, stage3DProxy : Stage3DProxy) : void
		{
			super.activate(vo, stage3DProxy);

			stage3DProxy.setTextureAt(vo.texturesIndex, _cubeTexture.getTextureForStage3D(stage3DProxy));
		}

		/**
		 * @inheritDoc
		 */
		arcane override function getFragmentCode(vo : MethodVO, regCache : ShaderRegisterCache, targetReg : ShaderRegisterElement) : ShaderChunk
		{
			var code : ShaderChunk = new ShaderChunk();
			var cubeMapReg : ShaderRegisterElement = regCache.getFreeTextureReg();
			vo.texturesIndex = cubeMapReg.index;

			code.tex( targetReg.value(), _normalFragmentReg.value(), cubeMapReg.value() |Tex.CUBE|Tex.LINEAR|Tex.MIPLINEAR|Tex.CLAMP );

			_ambientInputRegister = regCache.getFreeFragmentConstant();
			vo.fragmentConstantsIndex = _ambientInputRegister.index;

			code.add( targetReg.value() ^xyz, targetReg.value()^xyz,_ambientInputRegister.value()^xyz);

			return code;
		}
	}
}
