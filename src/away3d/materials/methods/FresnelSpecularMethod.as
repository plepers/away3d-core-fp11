package away3d.materials.methods
{
	import com.instagal.regs.*;
	import com.instagal.ShaderChunk;
	import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.utils.ShaderRegisterCache;
	import away3d.materials.utils.ShaderRegisterElement;

	import flash.display3D.Context3DProgramType;

	use namespace arcane;

	/**
	 * FresnelSpecularMethod provides a specular shading method that is stronger on shallow view angles.
	 */
	public class FresnelSpecularMethod extends CompositeSpecularMethod
	{
		private var _dataReg : ShaderRegisterElement;
        private var _incidentLight : Boolean;
        private var _fresnelPower : Number = 5;
		private var _normalReflectance : Number = .028;	// default value for skin

		/**
		 * Creates a new FresnelSpecularMethod object.
		 * @param basedOnSurface Defines whether the fresnel effect should be based on the view angle on the surface (if true), or on the angle between the light and the view.
		 * @param baseSpecularMethod
		 */
		public function FresnelSpecularMethod(basedOnSurface : Boolean = true, baseSpecularMethod : BasicSpecularMethod = null)
		{
            // may want to offer diff speculars
			super(modulateSpecular, baseSpecularMethod);
            _incidentLight = !basedOnSurface;
		}

		override arcane function initConstants(vo : MethodVO) : void
		{
			var index : int = vo.secondaryFragmentConstantsIndex;
			vo.fragmentData[index+2] = 1;
			vo.fragmentData[index+3] = 0;
		}

		public function get fresnelPower() : Number
		{
			return _fresnelPower;
		}

		public function set fresnelPower(value : Number) : void
		{
			_fresnelPower = value;
		}

		arcane override function cleanCompilationData() : void
		{
			super.cleanCompilationData();
			_dataReg = null;
		}

		/**
		 * The minimum amount of reflectance, ie the reflectance when the view direction is normal to the surface or light direction.
		 */
		public function get normalReflectance() : Number
		{
			return _normalReflectance;
		}

		public function set normalReflectance(value : Number) : void
		{
			_normalReflectance = value;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function activate(vo : MethodVO, stage3DProxy : Stage3DProxy) : void
		{
			super.activate(vo, stage3DProxy);
			var fragmentData : Vector.<Number> = vo.fragmentData;
			var index : int = vo.secondaryFragmentConstantsIndex;
			fragmentData[index] = _normalReflectance;
			fragmentData[index+1] = _fresnelPower;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function getFragmentPreLightingCode(vo : MethodVO, regCache : ShaderRegisterCache) : ShaderChunk
		{
			_dataReg = regCache.getFreeFragmentConstant();
			vo.secondaryFragmentConstantsIndex = _dataReg.index*4;
			return super.getFragmentPreLightingCode(vo, regCache);
		}

		/**
		 * Applies the fresnel effect to the specular strength.
		 *
		 * @param target The register containing the specular strength in the "w" component, and the half-vector/reflection vector in "xyz".
		 * @param regCache The register cache used for the shader compilation.
		 * @return The AGAL fragment code for the method.
		 */
		private function modulateSpecular(code : ShaderChunk, vo : MethodVO, target : ShaderRegisterElement, regCache : ShaderRegisterCache) : void
		{
			
			var vdr : uint = _viewDirFragmentReg.value();
			var nrm : uint = _normalFragmentReg.value();
			var ddr : uint = _dataReg.value();
			var tgt : uint = target.value();
			
			// use view dir and normal fragment .w as temp
            // use normal or half vector? :s
            code.dp3( vdr^w,    vdr^xyz,  (_incidentLight? tgt^xyz : nrm^xyz ) );
            code.sub( vdr^w,    ddr^z,    vdr^w);
            code.pow( nrm^w,    vdr^w,    ddr^y);
			code.sub( vdr^w,    ddr^z,    nrm^w);
			code.mul( vdr^w,    ddr^x,    vdr^w);
			code.add( vdr^w,    nrm^w,    vdr^w);
			code.mul( tgt^w, 	tgt^w,    tgt^w);

		}

	}
}
