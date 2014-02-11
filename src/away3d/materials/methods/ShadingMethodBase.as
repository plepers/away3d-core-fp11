package away3d.materials.methods
{
	import com.instagal.Tex;
	import com.instagal.ShaderChunk;
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.events.ShadingMethodEvent;
	import away3d.materials.passes.MaterialPassBase;
	import away3d.materials.utils.ShaderRegisterCache;
	import away3d.materials.utils.ShaderRegisterElement;

	import flash.events.EventDispatcher;

	use namespace arcane;

	/**
	 * ShadingMethodBase provides an abstract base method for shading methods, used by DefaultScreenPass to compile
	 * the final shading program.
	 */
	public class ShadingMethodBase extends EventDispatcher
	{
		protected var _viewDirVaryingReg : ShaderRegisterElement;
		protected var _viewDirFragmentReg : ShaderRegisterElement;
		protected var _normalFragmentReg : ShaderRegisterElement;
		protected var _normalVaryingReg : ShaderRegisterElement;
		protected var _uvFragmentReg : ShaderRegisterElement;
		protected var _secondaryUVFragmentReg : ShaderRegisterElement;
		protected var _vcFragmentReg : ShaderRegisterElement;
		protected var _tangentVaryingReg : ShaderRegisterElement;
		protected var _bitanVaryingReg : ShaderRegisterElement;
		protected var _globalPosReg : ShaderRegisterElement;
		protected var _projectionReg : ShaderRegisterElement;
		protected var _reflectVaryingReg : ShaderRegisterElement;
		protected var _refractVaryingReg : ShaderRegisterElement;
		protected var _commonFragReg : ShaderRegisterElement;
		protected var _extendedReg : ShaderRegisterElement;

		protected var _passes : Vector.<MaterialPassBase>;

		/**
		 * Create a new ShadingMethodBase object.
		 * @param needsNormals Defines whether or not the method requires normals.
		 * @param needsView Defines whether or not the method requires the view direction.
		 */
		public function ShadingMethodBase()  // needsNormals : Boolean, needsView : Boolean, needsGlobalPos : Boolean
		{
		}

		arcane function initVO(vo : MethodVO) : void
		{

		}

		arcane function initConstants(vo : MethodVO) : void
		{

		}

		/**
		 * Any passes required that render to a texture used by this method.
		 */
		public function get passes() : Vector.<MaterialPassBase>
		{
			return _passes;
		}

		/**
		 * Cleans up any resources used by the current object.
		 * @param deep Indicates whether other resources should be cleaned up, that could potentially be shared across different instances.
		 */
		public function dispose() : void
		{

		}

		/**
		 * Creates a data container that contains material-dependent data. Provided as a factory method so a custom subtype can be overridden when needed.
		 */
		arcane function createMethodVO() : MethodVO
		{
			return new MethodVO();
		}

		arcane function reset() : void
		{
			cleanCompilationData();
		}

		/**
		 * Resets the method's state for compilation.
		 * @private
		 */
		arcane function cleanCompilationData() : void
		{
			_viewDirVaryingReg = null;
			_viewDirFragmentReg = null;
			_normalFragmentReg = null;
			_uvFragmentReg = null;
			_globalPosReg = null;
			_projectionReg = null;
		}
		
		arcane function get tangentVaryingReg() : ShaderRegisterElement
		{
			return _tangentVaryingReg;
		}

		arcane function set tangentVaryingReg(value : ShaderRegisterElement) : void
		{
			_tangentVaryingReg = value;
		}
		
		
		arcane function get bitanVaryingReg() : ShaderRegisterElement {
			return _bitanVaryingReg;
		}

		arcane function set bitanVaryingReg(bitanVaryingReg : ShaderRegisterElement) : void {
			_bitanVaryingReg = bitanVaryingReg;
		}
		

		/**
		 * The fragment register in which the uv coordinates are stored.
		 * @private
		 */
		arcane function get globalPosReg() : ShaderRegisterElement
		{
			return _globalPosReg;
		}

		arcane function set globalPosReg(value : ShaderRegisterElement) : void
		{
			_globalPosReg = value;
		}

		arcane function get commonFragReg() : ShaderRegisterElement
		{
			return _commonFragReg;
		}

		arcane function set commonFragReg(value : ShaderRegisterElement) : void
		{
			_commonFragReg = value;
		}

		arcane function get projectionReg() : ShaderRegisterElement
		{
			return _projectionReg;
		}

		arcane function set projectionReg(value : ShaderRegisterElement) : void
		{
			_projectionReg = value;
		}

		/**
		 * The fragment register in which the uv coordinates are stored.
		 * @private
		 */
		arcane function get UVFragmentReg() : ShaderRegisterElement
		{
			return _uvFragmentReg;
		}

		arcane function set UVFragmentReg(value : ShaderRegisterElement) : void
		{
			_uvFragmentReg = value;
		}

		/**
		 * The fragment register in which the uv coordinates are stored.
		 * @private
		 */
		arcane function get secondaryUVFragmentReg() : ShaderRegisterElement
		{
			return _secondaryUVFragmentReg;
		}

		arcane function set secondaryUVFragmentReg(value : ShaderRegisterElement) : void
		{
			_secondaryUVFragmentReg = value;
		}


		arcane function get VCFragmentReg() : ShaderRegisterElement
		{
			return _vcFragmentReg;
		}

		arcane function set VCFragmentReg(value : ShaderRegisterElement) : void
		{
			_vcFragmentReg = value;
		}

		/**
		 * The fragment register in which the view direction is stored.
		 * @private
		 */
		arcane function get viewDirFragmentReg() : ShaderRegisterElement
		{
			return _viewDirFragmentReg;
		}

		arcane function set viewDirFragmentReg(value : ShaderRegisterElement) : void
		{
			_viewDirFragmentReg = value;
		}

		public function get viewDirVaryingReg() : ShaderRegisterElement
		{
			return _viewDirVaryingReg;
		}

		public function set viewDirVaryingReg(value : ShaderRegisterElement) : void
		{
			_viewDirVaryingReg = value;
		}

		/**
		 * The fragment register in which the normal is stored.
		 * @private
		 */
		arcane function get normalFragmentReg() : ShaderRegisterElement
		{
			return _normalFragmentReg;
		}

		arcane function set normalFragmentReg(value : ShaderRegisterElement) : void
		{
			_normalFragmentReg = value;
		}

		arcane function get normalVaryingReg() : ShaderRegisterElement
		{
			return _normalVaryingReg;
		}

		arcane function set normalVaryingReg(value : ShaderRegisterElement) : void
		{
			_normalVaryingReg = value;
		}

		arcane function get reflectVaryingReg() : ShaderRegisterElement
		{
			return _reflectVaryingReg;
		}

		arcane function set reflectVaryingReg(value : ShaderRegisterElement) : void
		{
			_reflectVaryingReg = value;
		}

		arcane function get refractVaryingReg() : ShaderRegisterElement
		{
			return _refractVaryingReg;
		}

		arcane function set refractVaryingReg(value : ShaderRegisterElement) : void
		{
			_refractVaryingReg = value;
		}

		arcane function get extendedReg() : ShaderRegisterElement
		{
			return _extendedReg;
		}

		arcane function set extendedReg(value : ShaderRegisterElement) : void
		{
			_extendedReg = value;
		}

		/**
		 * Get the vertex shader code for this method.
		 * @param regCache The register cache used during the compilation.
		 * @private
		 */
		arcane function getVertexCode(vo : MethodVO, regCache : ShaderRegisterCache) : ShaderChunk
		{
			return null;
		}

		/**
		 * Sets the render state for this method.
		 * @param context The Context3D currently used for rendering.
		 * @private
		 */
		arcane function activate(vo : MethodVO, stage3DProxy : Stage3DProxy) : void
		{

		}

		/**
		 * Sets the render state for a single renderable.
		 */
		arcane function setRenderState(vo : MethodVO, renderable : IRenderable, stage3DProxy : Stage3DProxy, camera : Camera3D) : void
		{

		}

		/**
		 * Clears the render state for this method.
		 * @param context The Context3D currently used for rendering.
		 * @private
		 */
		arcane function deactivate(vo : MethodVO, stage3DProxy : Stage3DProxy) : void
		{

		}

		/**
		 * A helper method that generates standard code for sampling from a texture using the normal uv coordinates.
		 * @param targetReg The register in which to store the sampled colour.
		 * @param inputReg The texture stream register.
		 * @return The fragment code that performs the sampling.
		 */
		protected function getTexSampleCode( chunk : ShaderChunk, vo : MethodVO, targetReg : ShaderRegisterElement, inputReg : ShaderRegisterElement, uvReg : ShaderRegisterElement = null, forceWrap : uint = 0, textype : uint = 0 ) : void
		{
			var wrap : uint = forceWrap || (vo.repeatTextures ? Tex.WRAP : Tex.CLAMP );
			var filter : uint = 0;
			
			if (vo.useSmoothTextures) filter |= Tex.LINEAR;
			else filter |= Tex.NEAREST;
			if( vo.useMipmapping ) 
				filter |= vo.useSmoothTextures ? Tex.MIPLINEAR : Tex.MIPNEAREST;
				
            uvReg ||= _uvFragmentReg;
			
			chunk.tex( targetReg.value(), uvReg.value(), inputReg.value() | wrap | filter | textype );
		}

		/**
		 * Marks the shader program as invalid, so it will be recompiled before the next render.
		 */
		protected function invalidateShaderProgram() : void
		{
			dispatchEvent(new ShadingMethodEvent(ShadingMethodEvent.SHADER_INVALIDATED));
		}

		/**
		 * Copies the state from a ShadingMethodBase object into the current object.
		 */
		public function copyFrom(method : ShadingMethodBase) : void
		{
		}

	

	}
}
