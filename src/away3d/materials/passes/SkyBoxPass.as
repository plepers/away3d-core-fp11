package away3d.materials.passes {

	import com.instagal.Tex;
	import com.instagal.regs.*;
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.core.managers.Stage3DProxy;
	import away3d.textures.CubeTextureBase;

	import com.instagal.Shader;
	import com.instagal.ShaderChunk;

	import flash.display3D.Context3DCompareMode;
	import flash.display3D.Context3DProgramType;

	use namespace arcane;

	/**
	 * SkyBoxPass provides a material pass exclusively used to render sky boxes from a cube texture.
	 */
	public class SkyBoxPass extends MaterialPassBase
	{
		protected var _cubeTexture : CubeTextureBase;

		/**
		 * Creates a new SkyBoxPass object.
		 */
		public function SkyBoxPass()
		{
			super();
			mipmap = false;
			_numUsedTextures = 1;
		}
		/**
		 * The cube texture to use as the skybox.
		 */
		public function get cubeTexture() : CubeTextureBase
		{
			return _cubeTexture;
		}

		public function set cubeTexture(value : CubeTextureBase) : void
		{
			_cubeTexture = value;
		}

		/**
		 * @inheritDoc
		 */
		arcane override function getVertexCode(code:ShaderChunk) : Shader
		{
			var sh : Shader = new Shader(Context3DProgramType.VERTEX);
			sh.m44( t7, a0, c0	);
			sh.mul( op, t7, c4	);
			sh.mov( v0, a0		);
			return sh;
		}

		/**
		 * @inheritDoc
		 */
		arcane override function getFragmentCode() : Shader
		{
			var sh : Shader = new Shader(Context3DProgramType.FRAGMENT);
			sh.tex( t0, v0, s0 |Tex.CUBE|Tex.LINEAR|Tex.CLAMP|Tex.MIPLINEAR	);
			sh.mov( oc, t0		);
			return sh;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function activate(stage3DProxy : Stage3DProxy, camera : Camera3D, textureRatioX : Number, textureRatioY : Number) : void
		{
			super.activate(stage3DProxy, camera, textureRatioX, textureRatioY);

			stage3DProxy._context3D.setDepthTest(false, Context3DCompareMode.LESS);
			stage3DProxy.setTextureAt(0, _cubeTexture.getTextureForStage3D(stage3DProxy));
		}
	}
}