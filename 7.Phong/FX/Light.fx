
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


void PhongDirectionalLight(Material mat,
							 DirLight L,  
							float3 normal,
							float3 toEye,//"顶点->眼"向量  
							out float4 ambient,
							out float4 diffuse,
							out float4 specular)  
{  
    //初始化  
    ambient = float4(0.0f, 0.0f, 0.0f, 0.0f);  
    diffuse = float4(0.0f, 0.0f, 0.0f, 0.0f);  
    specular = float4(0.0f, 0.0f, 0.0f, 0.0f);  
  
    //光照方向与光源方向相反  
    float3 lightVec = normalize(-L.dir);  
  
    //处理环境光数值  
    ambient = mat.ambient*L.ambient;  
  
    //计算漫反射和镜面反射，给物体表面提供光照  
    //求漫反射，注意两向量归一化  
    diffuse = max(dot(lightVec, normal), 0) * mat.diffuse * L.diffuse;;  
  
    //Phong 光照模型渲染  
    float3 v = reflect(-lightVec, normal);  
    float specFactor = pow(max(dot(v, toEye), 0.0f), mat.specular.w);  
    specular = specFactor * mat.specular * L.specular;  
  
} 