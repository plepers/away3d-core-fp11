package away3d.materials.passes
{
	import com.instagal.regs.*;
	import com.instagal.Shader;
	import com.instagal.ShaderChunk;
	import away3d.animators.IAnimator;
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.lightpickers.LightPickerBase;

	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.VertexBuffer3D;
	import flash.geom.Matrix3D;

	use namespace arcane;

	public class SegmentPass extends MaterialPassBase
	{
		protected static const ONE_VECTOR : Vector.<Number> = Vector.<Number>([ 1,1,1,1 ]);
		protected static const FRONT_VECTOR : Vector.<Number> = Vector.<Number>([ 0,0,-1,0 ]);

		private var _constants : Vector.<Number> = new Vector.<Number>(4, true);
		private var _calcMatrix : Matrix3D;
		private var _thickness : Number;

		/**
		 * Creates a new WireframePass object.
		 */
		public function SegmentPass(thickness : Number)
		{
			_calcMatrix = new Matrix3D();

			_thickness = thickness;
			_constants[1] = 1/255;

			super();
		}

		/**
		 * @inheritDoc
		 */
		arcane override function getVertexCode(code:ShaderChunk) : Shader
		{
			var sh : Shader = new Shader( Context3DProgramType.VERTEX );
			sh.m44( t0     , a0     , c8			);
			sh.m44( t1     , a1     , c8			);
			sh.sub( t2     , t1     , t0 			);
			sh.slt( t5^x   , t0^z   , c7^z	);
			sh.sub( t5^y   , c5^x   , t5^x	);
			sh.add( t4^x   , t0^z   , c7^z	);
			sh.sub( t4^y   , t0^z   , t1^z	);
			sh.div( t4^z   , t4^x   , t4^y	);
			sh.mul( t4^xyz , t4^z , t2^xyz	);
			sh.add( t3^xyz , t0^xyz , t4^xyz	);
			sh.mov( t3^w   , c5^x				);
			sh.mul( t0     , t0     , t5^y);
			sh.mul( t3     , t3     , t5^x);
			sh.add( t0     , t0     , t3		);
			sh.sub( t2     , t1     , t0 	);
			sh.nrm( t2^xyz , t2^xyz			);
			sh.nrm( t5^xyz , t0^xyz			);
			sh.mov( t5^w   , c5^x				);
			sh.crs( t3^xyz , t2     , t5		);
			sh.nrm( t3^xyz , t3^xyz			);
			sh.mul( t3^xyz , t3^xyz , a2^x	);
			sh.mov( t3^w   , c5^x				);
			sh.dp3( t4^x   , t0     , c6		);
			sh.mul( t4^x   , t4^x   , c7^x	);
			sh.mul( t3^xyz , t3^xyz , t4^x	);
			sh.add( t0^xyz , t0^xyz , t3^xyz	);
			sh.m44( t0     , t0     , c0		);
			sh.mul( op     , t0     , c4		);
			sh.mov( v0     , a3				);
			return sh;
		}

		/**
		 * @inheritDoc
		 */
		arcane override function getFragmentCode() : Shader
		{
			var sh : Shader = new Shader( Context3DProgramType.FRAGMENT );
			sh.mov( oc, v0 );
			return sh;
		}

		/**
		 * @inheritDoc
		 * todo: keep maps in dictionary per renderable
		 */
		arcane override function render(renderable : IRenderable, stage3DProxy : Stage3DProxy, camera : Camera3D, lightPicker : LightPickerBase) : void
		{
			var context : Context3D = stage3DProxy._context3D;
			var vertexBuffer : VertexBuffer3D = renderable.getVertexBuffer(stage3DProxy);
			context.setVertexBufferAt(0, vertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_3);
			context.setVertexBufferAt(1, vertexBuffer, 3, Context3DVertexBufferFormat.FLOAT_3);
			context.setVertexBufferAt(2, vertexBuffer, 6, Context3DVertexBufferFormat.FLOAT_1);
			context.setVertexBufferAt(3, vertexBuffer, 7, Context3DVertexBufferFormat.FLOAT_4);

			_calcMatrix.copyFrom(renderable.sourceEntity.sceneTransform);
			_calcMatrix.append(camera.inverseSceneTransform);
			context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 8, _calcMatrix, true);

			context.drawTriangles(renderable.getIndexBuffer(stage3DProxy), 0, renderable.numTriangles);
		}

		/**
		 * @inheritDoc
		 */
		override arcane function activate(stage3DProxy : Stage3DProxy, camera : Camera3D, textureRatioX : Number, textureRatioY : Number) : void
		{
			var context : Context3D = stage3DProxy._context3D;
			super.activate(stage3DProxy, camera, textureRatioX, textureRatioY);

			_constants[0] = _thickness/Math.min(stage3DProxy.width, stage3DProxy.height);
			// value to convert distance from camera to model length per pixel width
			_constants[2] = camera.lens.near;

			context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 5, ONE_VECTOR);
			context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 6, FRONT_VECTOR);
			context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 7, _constants);

			// projection matrix
			context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, camera.lens.matrix, true);
		}

		/**
		 * @inheritDoc
		 */
		arcane override function deactivate(stage3DProxy : Stage3DProxy) : void
		{
			stage3DProxy.setSimpleVertexBuffer(0, null, null, 0);
			stage3DProxy.setSimpleVertexBuffer(1, null, null, 0);
			stage3DProxy.setSimpleVertexBuffer(2, null, null, 0);
			stage3DProxy.setSimpleVertexBuffer(3, null, null, 0);
		}
	}
}