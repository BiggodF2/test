
//平行光
struct DirLight
{
	float4	ambient;	//环境光
	float4	diffuse;	//漫反射光
	float4	specular;	//高光

	float3	dir;		//方向
	float	unused;		//“4D向量”对齐用
};

//点光源
struct PointLight
{
	float4	ambient;	//环境光
	float4	diffuse;	//漫反射光
	float4	specular;	//高光

	float3	pos;		//光源位置
	float	range;		//光源照射范围

	float3	att;		//光强衰减系数
	float	unused;		//"4D向量"对齐用
};

//聚光灯
struct SpotLight
{
	float4	ambient;	//环境光
	float4	diffuse;	//漫反射光
	float4	specular;	//高光

	float3	dir;		//方向
	float	range;		//照射范围

	float3	pos;		//位置
	float	spot;		//聚光强度系数

	float3	att;		//误差系数
	float	theta;		//最大发散角度
};

//材质
struct Material
{
	float4	ambient;
	float4	diffuse;
	float4	specular;	//specular中第4个元素代表材质的表面光滑程度
};

void BankBRDF(  Material mat,
				DirLight L,
				float3	position,//顶点位置
				float3	normal,
				float3	toEye,
				out 	float4 ambient,
				out		float4 diffuse,
				out		float4 specular)
{
	//初始化  
    ambient  = float4(0.f,0.f,0.f,0.f);
	diffuse  = float4(0.f,0.f,0.f,0.f);
	specular = float4(0.f,0.f,0.f,0.f);
	float  g_shininess  = 20.0f ;
	ambient = mat.ambient * L.ambient;
	float ln = saturate(dot(L.dir,normal));
	// 计算漫反射光强
	diffuse = mat.diffuse*ln;
	
	bool back = (dot(L.dir,normal)) && (dot(normal,toEye)>0);
	
	// 若不满足条件则高光为0 
	if (back)
	{
	// 计算顶点切向量 
	float3 T  =  normalize( cross( normal, toEye ) ); 
	float LT  =  dot(L.dir, T );
	float VT  =  dot( toEye, T );
	float a  =  sqrt(  1 -  pow( LT,2.0f) )  *  sqrt(  1 -  pow( VT,  2.0f  ) )  -  LT  *  VT;
	specular.xyz  =  pow( a, g_shininess )*mat.specular*ln;
	specular.w = 1;	
	}
}

