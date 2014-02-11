package away3d.materials.methods
{
	import com.instagal.regs.*;
	import com.instagal.ShaderChunk;
	import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.methods.MethodVO;
	import away3d.materials.utils.ShaderRegisterCache;
	import away3d.materials.utils.ShaderRegisterElement;

	import flash.display3D.Context3DProgramType;

	use namespace arcane;

	/**
	 * CelDiffuseMethod provides a shading method to add specular cel (cartoon) shading.
	 */
	public class CelDiffuseMethod extends CompositeDiffuseMethod
	{
		private var _levels : uint;
		private var _dataReg : ShaderRegisterElement;
		private var _smoothness : Number = .1;

		/**
		 * Creates a new CelDiffuseMethod object.
		 * @param levels The amount of shadow gradations.
		 * @param baseDiffuseMethod An optional diffuse method on which the cartoon shading is based. If ommitted, BasicDiffuseMethod is used.
		 */
		public function CelDiffuseMethod(levels : uint = 3, baseDiffuseMethod : BasicDiffuseMethod = null)
		{
			super(clampDiffuse, baseDiffuseMethod);

			_levels = levels;
		}

		override arcane function initConstants(vo : MethodVO) : void
		{
			var data : Vector.<Number> = vo.fragmentData;
			var index : int = vo.secondaryFragmentConstantsIndex;
			super.initConstants(vo);
			data[index+1] = 1;
			data[index+2] = 0;
		}

		public function get levels() : uint
		{
			return _levels;
		}

		public function set levels(value : uint) : void
		{
			_levels = value;
		}

		/**
		 * The smoothness of the edge between 2 shading levels.
		 */
		public function get smoothness() : Number
		{
			return _smoothness;
		}

		public function set smoothness(value : Number) : void
		{
			_smoothness = value;
		}

		/**
		 * @inheritDoc
		 */
		arcane override function cleanCompilationData() : void
		{
			super.cleanCompilationData();
			_dataReg = null;
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
		 * @inheritDoc
		 */
		override arcane function activate(vo : MethodVO, stage3DProxy : Stage3DProxy) : void
		{
			super.activate(vo, stage3DProxy);
			var data : Vector.<Number> = vo.fragmentData;
			var index : int = vo.secondaryFragmentConstantsIndex;
			data[index] =_levels;
			data[index+3] = _smoothness;
		}

		/**
		 * Snaps the diffuse shading of the wrapped method to one of the levels.
		 * @param t The register containing the diffuse strength in the "w" component.
		 * @param regCache The register cache used for the shader compilation.
		 * @return The AGAL fragment code for the method.
		 */
		private function clampDiffuse( code : ShaderChunk, vo : MethodVO, t : ShaderRegisterElement, regCache : ShaderRegisterCache) : void
		{
			var tr : uint = t.value();
			var dr : uint = _dataReg.value();
			
			code.mul( tr^w, tr^w, dr^x	);
			code.frc( tr^z, tr^w		);
			code.sub( tr^y, tr^w, tr^z	);
			code.mov( tr^x, dr^x		);
			code.sub( tr^x, tr^x, dr^y	);
			code.rcp( tr^x, tr^x		);
			code.mul( tr^w, tr^y, tr^x	);
			code.sub( tr^y, tr^w, tr^x	);
			code.div( tr^z, tr^z, dr^w	);
			code.sat( tr^z, tr^z		);
			code.mul( tr^w, tr^w, tr^z	);
			code.sub( tr^z, dr^y, tr^z	);
			code.mul( tr^y, tr^y, tr^z	);
			code.add( tr^w, tr^w, tr^y	);
			code.sat( tr^w, tr^w		);
		}
	}
}
