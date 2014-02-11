package away3d.materials
{
	import away3d.arcane;
	import away3d.materials.passes.SkyBoxPass;
	import away3d.textures.CubeTextureBase;

	use namespace arcane;

	/**
	 * SkyBoxMaterial is a material exclusively used to render skyboxes
	 *
	 * @see away3d.primitives.SkyBox
	 */
	public class SkyBoxMaterial extends MaterialBase
	{
		protected var _cubeMap : CubeTextureBase;
		protected var _skyboxPass : SkyBoxPass;

		/**
		 * Creates a new SkyBoxMaterial object.
		 * @param cubeMap The CubeMap to use as the skybox.
		 */
		public function SkyBoxMaterial(cubeMap : CubeTextureBase)
		{
			_cubeMap = cubeMap;
			addPass(_skyboxPass = createPass());
			_skyboxPass.cubeTexture = _cubeMap;
		}

		protected function createPass() : SkyBoxPass {
			return new SkyBoxPass();
		}


		/**
		 * The CubeMap to use as the skybox.
		 */
		public function get cubeMap() : CubeTextureBase
		{
			return _cubeMap;
		}

		public function set cubeMap(value : CubeTextureBase) : void
		{
			_cubeMap = value;
		}
	}
}
