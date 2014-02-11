package away3d.materials.methods
{
	import com.instagal.Tex;
	import com.instagal.regs.*;
	import com.instagal.ShaderChunk;
	import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.utils.ShaderRegisterCache;
	import away3d.materials.utils.ShaderRegisterElement;
	import away3d.textures.CubeTextureBase;

	import flash.display3D.Context3DProgramType;

	use namespace arcane;

	public class EnvMapMethod extends EffectMethodBase
	{
		private var _cubeTexture : CubeTextureBase;
		private var _alpha : Number;

		public function EnvMapMethod(envMap : CubeTextureBase = null, alpha : Number = 1)
		{
			super();
			_cubeTexture = envMap;
			_alpha = alpha;
		}

		override arcane function initVO(vo : MethodVO) : void
		{
			vo.needsNormals = true;
			vo.needsView = true;
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
		override public function dispose() : void
		{
		}

		public function get alpha() : Number
		{
			return _alpha;
		}

		public function set alpha(value : Number) : void
		{
			_alpha = value;
		}

		arcane override function activate(vo : MethodVO, stage3DProxy : Stage3DProxy) : void
		{
			vo.fragmentData[vo.fragmentConstantsIndex] = _alpha;
			stage3DProxy.setTextureAt(vo.texturesIndex, _cubeTexture.getTextureForStage3D(stage3DProxy));
		}

		arcane override function getFragmentCode(vo : MethodVO, regCache : ShaderRegisterCache, targetReg : ShaderRegisterElement) : ShaderChunk
		{
			var dataRegister : ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var temp : ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
			var code : ShaderChunk = new ShaderChunk();
			var cubeMapReg : ShaderRegisterElement = regCache.getFreeTextureReg();
			vo.texturesIndex = cubeMapReg.index;
			vo.fragmentConstantsIndex = dataRegister.index*4;
			var tp : uint = temp.value();
			
			// r = I - 2(I.N)*N
			code.dp3( tp ^w			, _viewDirFragmentReg.value()^xyz, _normalFragmentReg.value()^xyz );
			code.add( tp ^w			, tp ^w, tp ^w							);
			code.mul( tp ^xyz		, _normalFragmentReg.value() ^xyz,  tp ^w		);
			code.sub( tp ^xyz		, _viewDirFragmentReg.value() ^xyz, tp ^xyz		);
			code.neg( tp ^xyz		, tp ^xyz								);
			code.tex( tp 			, tp , ( cubeMapReg.value() |Tex.CUBE| (vo.useSmoothTextures? Tex.LINEAR:Tex.NEAREST) |Tex.MIPLINEAR|Tex.CLAMP ) );
			code.sub( tp 			, tp , targetReg.value()					);
			code.mul( tp 			, tp , dataRegister.value() ^x				);
			code.add( targetReg.value() ^xyz, targetReg.value()^xyz, tp ^xyz			);

			return code;
		}
	}
}
